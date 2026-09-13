// practice: data access.
//
// Defines the repository interface consumed by service.go plus its PostgreSQL
// implementation. Translates database rows to and from domain models.
//
// Contains NO business rules: whether a day is unlocked is decided in the service. What is
// here is storage — including the one transaction that matters, creating a session and its
// items together, because a session with no items is not a practice set.
//
// See ARCHITECTURE.md 13, 5.3, 10.3 (schema).

package practice

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/samandar-hodiev/voca/backend/internal/word"
)

var ErrNotFound = errors.New("practice: not found")

type Repository interface {
	// LastDailySession is the most recent daily session, whenever it was. The service
	// needs the last one rather than today's, because an unpassed set from a previous day
	// is still the set the learner owes.
	LastDailySession(ctx context.Context, userID uuid.UUID) (Session, error)

	SessionByID(ctx context.Context, id uuid.UUID) (Session, error)
	Items(ctx context.Context, sessionID uuid.UUID) ([]Item, error)

	// CreateDailySession writes the session and its items in one transaction.
	CreateDailySession(ctx context.Context, userID uuid.UUID, day time.Time,
		words []word.Word) (Session, error)

	// PassedWordIDs are the words this learner has already got right, so a new day does
	// not hand them back the ones they have finished with.
	PassedWordIDs(ctx context.Context, userID uuid.UUID) ([]uuid.UUID, error)

	CompleteSession(ctx context.Context, id uuid.UUID, average float64) error

	// RecordItemResult stores an attempt against the item for that word in the learner's
	// current session. Keeps the best score, not the last: retries are unlimited and it is
	// the best attempt that counts.
	//
	// Keyed by the word's TEXT rather than its id, because that is what an attempt carries:
	// the app sends the reference text it asked the learner to say. MVP practice is single
	// words, so the text identifies the row.
	RecordItemResult(ctx context.Context, userID uuid.UUID, wordText string,
		attemptID uuid.UUID, score float64, passScore float64) error

	RecentDailySessions(ctx context.Context, userID uuid.UUID, limit int) ([]Session, error)
}

type repository struct{ pool *pgxpool.Pool }

func NewRepository(pool *pgxpool.Pool) Repository { return &repository{pool: pool} }

const sessionColumns = `id, user_id, session_type, content_type, status, item_count,
	completed_item_count, average_score, practice_day, started_at, completed_at`

func scanSession(row pgx.Row) (Session, error) {
	var s Session
	err := row.Scan(&s.ID, &s.UserID, &s.Type, &s.ContentType, &s.Status, &s.ItemCount,
		&s.CompletedItemCount, &s.AverageScore, &s.PracticeDay, &s.StartedAt, &s.CompletedAt)
	return s, err
}

func (r *repository) LastDailySession(ctx context.Context, userID uuid.UUID) (Session, error) {
	s, err := scanSession(r.pool.QueryRow(ctx,
		`SELECT `+sessionColumns+`
		   FROM practice_sessions
		  WHERE user_id = $1 AND session_type = 'daily'
		  ORDER BY practice_day DESC
		  LIMIT 1`, userID))
	if errors.Is(err, pgx.ErrNoRows) {
		return Session{}, ErrNotFound
	}
	if err != nil {
		return Session{}, fmt.Errorf("practice: last daily session: %w", err)
	}
	return s, nil
}

func (r *repository) SessionByID(ctx context.Context, id uuid.UUID) (Session, error) {
	s, err := scanSession(r.pool.QueryRow(ctx,
		`SELECT `+sessionColumns+` FROM practice_sessions WHERE id = $1`, id))
	if errors.Is(err, pgx.ErrNoRows) {
		return Session{}, ErrNotFound
	}
	if err != nil {
		return Session{}, fmt.Errorf("practice: session by id: %w", err)
	}
	return s, nil
}

func (r *repository) Items(ctx context.Context, sessionID uuid.UUID) ([]Item, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT i.id, i.word_id, i.position, i.status, i.best_score, i.best_attempt_id,
		        i.attempt_count,
		        w.text, coalesce(w.phonetic_ipa, ''), w.target_phonemes,
		        coalesce(w.cefr_level, ''), coalesce(w.meaning_uz, '')
		   FROM practice_items i
		   JOIN words w ON w.id = i.word_id
		  WHERE i.session_id = $1
		  ORDER BY i.position`, sessionID)
	if err != nil {
		return nil, fmt.Errorf("practice: items: %w", err)
	}
	defer rows.Close()

	out := []Item{}
	for rows.Next() {
		var it Item
		if err := rows.Scan(&it.ID, &it.WordID, &it.Position, &it.Status, &it.BestScore,
			&it.BestAttemptID, &it.AttemptCount,
			&it.Word.Text, &it.Word.PhoneticIPA, &it.Word.TargetPhonemes,
			&it.Word.CEFRLevel, &it.Word.MeaningUz); err != nil {
			return nil, fmt.Errorf("practice: scan item: %w", err)
		}
		it.Word.ID = it.WordID
		out = append(out, it)
	}
	return out, rows.Err()
}

func (r *repository) CreateDailySession(
	ctx context.Context, userID uuid.UUID, day time.Time, words []word.Word,
) (Session, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return Session{}, fmt.Errorf("practice: begin: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	s, err := scanSession(tx.QueryRow(ctx,
		`INSERT INTO practice_sessions
		   (user_id, session_type, content_type, status, item_count, practice_day)
		 VALUES ($1, 'daily', 'word', 'in_progress', $2, $3)
		 RETURNING `+sessionColumns, userID, len(words), day))
	if err != nil {
		return Session{}, fmt.Errorf("practice: create session: %w", err)
	}

	for i, w := range words {
		if _, err := tx.Exec(ctx,
			`INSERT INTO practice_items (session_id, word_id, position)
			 VALUES ($1, $2, $3)`, s.ID, w.ID, i); err != nil {
			return Session{}, fmt.Errorf("practice: create item: %w", err)
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return Session{}, fmt.Errorf("practice: commit: %w", err)
	}
	return s, nil
}

func (r *repository) PassedWordIDs(ctx context.Context, userID uuid.UUID) ([]uuid.UUID, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT DISTINCT i.word_id
		   FROM practice_items i
		   JOIN practice_sessions s ON s.id = i.session_id
		  WHERE s.user_id = $1 AND i.status = 'completed'`, userID)
	if err != nil {
		return nil, fmt.Errorf("practice: passed words: %w", err)
	}
	defer rows.Close()

	out := []uuid.UUID{}
	for rows.Next() {
		var id uuid.UUID
		if err := rows.Scan(&id); err != nil {
			return nil, fmt.Errorf("practice: scan passed word: %w", err)
		}
		out = append(out, id)
	}
	return out, rows.Err()
}

func (r *repository) CompleteSession(
	ctx context.Context, id uuid.UUID, average float64,
) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE practice_sessions
		    SET status = 'completed', average_score = $2, completed_at = now()
		  WHERE id = $1`, id, average)
	if err != nil {
		return fmt.Errorf("practice: complete session: %w", err)
	}
	return nil
}

func (r *repository) RecordItemResult(
	ctx context.Context, userID uuid.UUID, wordText string,
	attemptID uuid.UUID, score, passScore float64,
) error {
	// Scoped to the learner's own open session, so an attempt can never touch somebody
	// else's item, and greatest() keeps the best rather than the most recent.
	_, err := r.pool.Exec(ctx,
		`UPDATE practice_items i
		    SET attempt_count = i.attempt_count + 1,
		        best_score = greatest(coalesce(i.best_score, 0), $3),
		        best_attempt_id = CASE
		            WHEN i.best_score IS NULL OR $3 > i.best_score THEN $4
		            ELSE i.best_attempt_id END,
		        status = CASE
		            WHEN greatest(coalesce(i.best_score, 0), $3) >= $5 THEN 'completed'
		            ELSE 'attempted' END,
		        updated_at = now()
		   FROM practice_sessions s, words w
		  WHERE i.session_id = s.id
		    AND w.id = i.word_id
		    AND s.user_id = $1 AND s.status = 'in_progress'
		    AND lower(w.text) = lower($2)`, userID, wordText, score, attemptID, passScore)
	if err != nil {
		return fmt.Errorf("practice: record item result: %w", err)
	}

	// completed_item_count is denormalized, so it is recomputed rather than incremented:
	// an item can pass, then be retried, and a counter that only goes up would drift.
	_, err = r.pool.Exec(ctx,
		`UPDATE practice_sessions s
		    SET completed_item_count = (
		          SELECT count(*) FROM practice_items i
		           WHERE i.session_id = s.id AND i.status = 'completed')
		  WHERE s.user_id = $1 AND s.status = 'in_progress'`, userID)
	if err != nil {
		return fmt.Errorf("practice: refresh counters: %w", err)
	}
	return nil
}

func (r *repository) RecentDailySessions(
	ctx context.Context, userID uuid.UUID, limit int,
) ([]Session, error) {
	if limit <= 0 || limit > 60 {
		limit = 14
	}
	rows, err := r.pool.Query(ctx,
		`SELECT `+sessionColumns+`
		   FROM practice_sessions
		  WHERE user_id = $1 AND session_type = 'daily'
		  ORDER BY practice_day DESC
		  LIMIT $2`, userID, limit)
	if err != nil {
		return nil, fmt.Errorf("practice: recent sessions: %w", err)
	}
	defer rows.Close()

	out := []Session{}
	for rows.Next() {
		s, err := scanSession(rows)
		if err != nil {
			return nil, fmt.Errorf("practice: scan session: %w", err)
		}
		out = append(out, s)
	}
	return out, rows.Err()
}
