// progress: data access.
//
// Defines the repository interface consumed by service.go plus its PostgreSQL
// implementation. Translates database rows to and from domain models.
//
// Contains NO business rules: the streak arithmetic and the week/previous-week comparison
// live in the service. What is here is what the database is genuinely better at — grouping,
// averaging and de-duplicating across a lot of rows.
//
// Every query reads this module's OWN view of another module's tables through the same
// indexes that module created: pronunciation_attempts (user_id, created_at DESC) and
// phoneme_results (user_id, phoneme).
//
// See ARCHITECTURE.md 14, 5.3, 10 (schema).

package progress

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository interface {
	// AttemptsSince returns this learner's attempts, newest first, for bucketing by day.
	AttemptsSince(ctx context.Context, userID uuid.UUID, since time.Time) ([]RecentAttempt, error)

	// PracticeDays lists the distinct local dates this learner practised on, newest
	// first. The timezone conversion happens in SQL because the date boundary is what is
	// being grouped by.
	PracticeDays(ctx context.Context, userID uuid.UUID, timezone string, limit int) ([]time.Time, error)

	// DistinctWords counts how many different words have ever been attempted.
	DistinctWords(ctx context.Context, userID uuid.UUID) (int, error)

	// WeakSounds are the phonemes this learner is actually getting wrong: scoring below
	// maxAccuracy, with enough samples to mean something.
	WeakSounds(ctx context.Context, userID uuid.UUID, minSamples, maxAccuracy, limit int) ([]WeakSound, error)

	// RecentAttempts is the tail of the history, for the list at the bottom of the screen.
	RecentAttempts(ctx context.Context, userID uuid.UUID, limit int) ([]RecentAttempt, error)
}

type repository struct{ pool *pgxpool.Pool }

func NewRepository(pool *pgxpool.Pool) Repository { return &repository{pool: pool} }

func (r *repository) AttemptsSince(
	ctx context.Context, userID uuid.UUID, since time.Time,
) ([]RecentAttempt, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT reference_text, coalesce(overall_score, 0), created_at
		   FROM pronunciation_attempts
		  WHERE user_id = $1 AND created_at >= $2
		  ORDER BY created_at DESC`, userID, since)
	if err != nil {
		return nil, fmt.Errorf("progress: attempts since: %w", err)
	}
	defer rows.Close()
	return scanAttempts(rows)
}

func (r *repository) RecentAttempts(
	ctx context.Context, userID uuid.UUID, limit int,
) ([]RecentAttempt, error) {
	if limit <= 0 || limit > 100 {
		limit = 10
	}
	rows, err := r.pool.Query(ctx,
		`SELECT reference_text, coalesce(overall_score, 0), created_at
		   FROM pronunciation_attempts
		  WHERE user_id = $1
		  ORDER BY created_at DESC
		  LIMIT $2`, userID, limit)
	if err != nil {
		return nil, fmt.Errorf("progress: recent attempts: %w", err)
	}
	defer rows.Close()
	return scanAttempts(rows)
}

func (r *repository) PracticeDays(
	ctx context.Context, userID uuid.UUID, timezone string, limit int,
) ([]time.Time, error) {
	if limit <= 0 {
		limit = 400
	}
	// AT TIME ZONE turns the stored instant into the learner's wall clock before the date
	// is taken, which is the whole point: practising at 00:30 in Tashkent is today, not
	// yesterday as UTC would have it.
	rows, err := r.pool.Query(ctx,
		`SELECT DISTINCT (created_at AT TIME ZONE $2)::date AS d
		   FROM pronunciation_attempts
		  WHERE user_id = $1
		  ORDER BY d DESC
		  LIMIT $3`, userID, timezone, limit)
	if err != nil {
		return nil, fmt.Errorf("progress: practice days: %w", err)
	}
	defer rows.Close()

	var out []time.Time
	for rows.Next() {
		var d time.Time
		if err := rows.Scan(&d); err != nil {
			return nil, fmt.Errorf("progress: scan day: %w", err)
		}
		out = append(out, d)
	}
	return out, rows.Err()
}

func (r *repository) DistinctWords(ctx context.Context, userID uuid.UUID) (int, error) {
	var n int
	err := r.pool.QueryRow(ctx,
		`SELECT count(DISTINCT lower(reference_text))
		   FROM pronunciation_attempts WHERE user_id = $1`, userID).Scan(&n)
	if err != nil {
		return 0, fmt.Errorf("progress: distinct words: %w", err)
	}
	return n, nil
}

func (r *repository) WeakSounds(
	ctx context.Context, userID uuid.UUID, minSamples, maxAccuracy, limit int,
) ([]WeakSound, error) {
	if minSamples <= 0 {
		minSamples = 3
	}
	if maxAccuracy <= 0 {
		maxAccuracy = 80
	}
	if limit <= 0 {
		limit = 5
	}
	// Two filters, both necessary. The sample floor keeps one unlucky recording from being
	// presented as a weakness. The accuracy ceiling keeps SOUNDS THE LEARNER SAYS WELL out
	// of a list headed "weak sounds" — without it, somebody who has only practised a
	// little sees every sound they have ever said, including the ones they scored 100 on.
	//
	// The ceiling is the same 80 the analyzer uses to decide a sound needs work, and the
	// same one the app uses to colour a score. Four places, one line.
	//
	// The example is the most recent word the sound was heard in, which is the one the
	// learner is most likely to remember saying.
	rows, err := r.pool.Query(ctx,
		`SELECT phoneme,
		        round(avg(accuracy_score))::int AS accuracy,
		        (array_agg(word ORDER BY created_at DESC))[1] AS example
		   FROM phoneme_results
		  WHERE user_id = $1
		  GROUP BY phoneme
		 HAVING count(*) >= $2 AND avg(accuracy_score) < $3
		  ORDER BY accuracy ASC
		  LIMIT $4`, userID, minSamples, maxAccuracy, limit)
	if err != nil {
		return nil, fmt.Errorf("progress: weak sounds: %w", err)
	}
	defer rows.Close()

	var out []WeakSound
	for rows.Next() {
		var w WeakSound
		if err := rows.Scan(&w.Phoneme, &w.Accuracy, &w.Example); err != nil {
			return nil, fmt.Errorf("progress: scan weak sound: %w", err)
		}
		out = append(out, w)
	}
	return out, rows.Err()
}

type rowScanner interface {
	Next() bool
	Scan(dest ...any) error
	Err() error
}

func scanAttempts(rows rowScanner) ([]RecentAttempt, error) {
	var out []RecentAttempt
	for rows.Next() {
		var (
			a     RecentAttempt
			score float64
		)
		if err := rows.Scan(&a.Word, &score, &a.At); err != nil {
			return nil, fmt.Errorf("progress: scan attempt: %w", err)
		}
		a.Score = int(score + 0.5)
		out = append(out, a)
	}
	return out, rows.Err()
}
