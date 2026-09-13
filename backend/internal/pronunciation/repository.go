// pronunciation: data access.
//
// Defines the repository interface consumed by service.go plus its PostgreSQL
// implementation. Translates database rows to and from domain models.
//
// Contains NO business rules. The transaction boundary belongs to the service, which is
// why SaveAttempt takes the whole attempt and writes its three tables together: an attempt
// without its phonemes would corrupt the weak-sound aggregation.
//
// See ARCHITECTURE.md 6, 5.3, 10 (schema).

package pronunciation

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository interface {
	// SaveAttempt writes the attempt, its phoneme results and its feedback in one
	// transaction, and returns the new attempt's ID and the time the database stamped
	// on it. The timestamp is read back rather than generated here so the value the app
	// is shown is the value that was stored, in the database's clock.
	SaveAttempt(ctx context.Context, a Attempt) (uuid.UUID, time.Time, error)

	// RecentAttempts is the learner's own history, newest first.
	RecentAttempts(ctx context.Context, userID uuid.UUID, limit int) ([]Attempt, error)
}

type repository struct{ pool *pgxpool.Pool }

func NewRepository(pool *pgxpool.Pool) Repository { return &repository{pool: pool} }

func (r *repository) SaveAttempt(ctx context.Context, a Attempt) (uuid.UUID, time.Time, error) {
	words, err := json.Marshal(a.Words)
	if err != nil {
		return uuid.Nil, time.Time{}, fmt.Errorf("pronunciation: encode word results: %w", err)
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return uuid.Nil, time.Time{}, fmt.Errorf("pronunciation: begin: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	var id uuid.UUID
	var createdAt time.Time
	err = tx.QueryRow(ctx,
		`INSERT INTO pronunciation_attempts
		   (user_id, reference_text, language, provider, scoring_version, status,
		    accuracy_score, fluency_score, completeness_score, overall_score,
		    recognized_text, word_results, audio_duration_ms)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
		 RETURNING id, created_at`,
		a.UserID, a.ReferenceText, a.Language, a.Provider, a.ScoringVersion, a.Status,
		a.Scores.Accuracy, a.Scores.Fluency, a.Scores.Completeness, a.Scores.Overall,
		a.RecognizedText, words, a.AudioDurationMS,
	).Scan(&id, &createdAt)
	if err != nil {
		return uuid.Nil, time.Time{}, fmt.Errorf("pronunciation: insert attempt: %w", err)
	}

	// Phonemes are a real table because the weak-sound service aggregates them across
	// attempts; the word results above are JSONB because they are only ever read back
	// with their own attempt (docs/database/erd.md).
	for _, w := range a.Words {
		for _, p := range w.Phonemes {
			if _, err := tx.Exec(ctx,
				`INSERT INTO phoneme_results (attempt_id, user_id, phoneme, word, accuracy_score)
				 VALUES ($1, $2, $3, $4, $5)`,
				id, a.UserID, p.Phoneme, w.Word, p.Accuracy,
			); err != nil {
				return uuid.Nil, time.Time{}, fmt.Errorf("pronunciation: insert phoneme: %w", err)
			}
		}
	}

	for _, f := range a.Feedback {
		if _, err := tx.Exec(ctx,
			`INSERT INTO feedback (attempt_id, user_id, message_key, tip_key, word, phoneme, priority)
			 VALUES ($1, $2, $3, $4, $5, $6, $7)`,
			id, a.UserID, f.MessageKey, nullable(f.TipKey), nullable(f.Word),
			nullable(f.Phoneme), f.Priority,
		); err != nil {
			return uuid.Nil, time.Time{}, fmt.Errorf("pronunciation: insert feedback: %w", err)
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return uuid.Nil, time.Time{}, fmt.Errorf("pronunciation: commit: %w", err)
	}
	return id, createdAt, nil
}

func (r *repository) RecentAttempts(
	ctx context.Context, userID uuid.UUID, limit int,
) ([]Attempt, error) {
	if limit <= 0 || limit > 100 {
		limit = 20
	}

	rows, err := r.pool.Query(ctx,
		`SELECT id, reference_text, language, provider, scoring_version, status,
		        coalesce(accuracy_score, 0), coalesce(fluency_score, 0),
		        coalesce(completeness_score, 0), coalesce(overall_score, 0),
		        coalesce(recognized_text, ''), word_results,
		        coalesce(audio_duration_ms, 0), created_at
		   FROM pronunciation_attempts
		  WHERE user_id = $1
		  ORDER BY created_at DESC
		  LIMIT $2`, userID, limit)
	if err != nil {
		return nil, fmt.Errorf("pronunciation: list attempts: %w", err)
	}
	defer rows.Close()

	var out []Attempt
	for rows.Next() {
		var (
			a         Attempt
			wordsJSON []byte
			created   time.Time
		)
		if err := rows.Scan(&a.ID, &a.ReferenceText, &a.Language, &a.Provider,
			&a.ScoringVersion, &a.Status,
			&a.Scores.Accuracy, &a.Scores.Fluency, &a.Scores.Completeness, &a.Scores.Overall,
			&a.RecognizedText, &wordsJSON, &a.AudioDurationMS, &created,
		); err != nil {
			return nil, fmt.Errorf("pronunciation: scan attempt: %w", err)
		}
		if len(wordsJSON) > 0 {
			// A row whose JSON cannot be read is still a real attempt: return it with
			// the scores rather than failing the whole history.
			_ = json.Unmarshal(wordsJSON, &a.Words)
		}
		a.UserID = userID
		a.CreatedAt = created
		out = append(out, a)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("pronunciation: read attempts: %w", err)
	}
	return out, nil
}

// nullable stores an empty optional as SQL NULL rather than an empty string, so "no word"
// and "the empty word" stay different things in the data.
func nullable(s string) any {
	if s == "" {
		return nil
	}
	return s
}

// compile-time proof the driver types are the ones this file claims to use.
var _ pgx.Tx = (pgx.Tx)(nil)
