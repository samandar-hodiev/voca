// word: data access.
//
// Defines the repository interface consumed by service.go plus its PostgreSQL
// implementation. Translates database rows to and from domain models.
//
// Contains NO business rules.
//
// See ARCHITECTURE.md 13.4, 5.3, 10.2 (schema).

package word

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var ErrNotFound = errors.New("word: not found")

type Repository interface {
	ByID(ctx context.Context, id uuid.UUID) (Word, error)
	List(ctx context.Context, f Filter) ([]Word, error)
	Candidates(ctx context.Context, q CandidateQuery) ([]Word, error)
	Categories(ctx context.Context) ([]Category, error)
}

type repository struct{ pool *pgxpool.Pool }

func NewRepository(pool *pgxpool.Pool) Repository { return &repository{pool: pool} }

const columns = `id, text, language, accent, coalesce(phonetic_ipa, ''),
	coalesce(phonetic_respelling, ''), target_phonemes, coalesce(audio_url, ''),
	category_id, difficulty_level, coalesce(cefr_level, ''),
	coalesce(part_of_speech, ''), coalesce(meaning_uz, ''),
	coalesce(example_sentence, ''), frequency_rank`

func scan(row pgx.Row) (Word, error) {
	var w Word
	err := row.Scan(&w.ID, &w.Text, &w.Language, &w.Accent, &w.PhoneticIPA,
		&w.PhoneticRespelling, &w.TargetPhonemes, &w.AudioURL, &w.CategoryID,
		&w.DifficultyLevel, &w.CEFRLevel, &w.PartOfSpeech, &w.MeaningUz,
		&w.ExampleSentence, &w.FrequencyRank)
	return w, err
}

func (r *repository) ByID(ctx context.Context, id uuid.UUID) (Word, error) {
	w, err := scan(r.pool.QueryRow(ctx,
		`SELECT `+columns+` FROM words WHERE id = $1 AND is_active`, id))
	if errors.Is(err, pgx.ErrNoRows) {
		return Word{}, ErrNotFound
	}
	if err != nil {
		return Word{}, fmt.Errorf("word: by id: %w", err)
	}
	return w, nil
}

func (r *repository) List(ctx context.Context, f Filter) ([]Word, error) {
	if f.Limit <= 0 || f.Limit > 100 {
		f.Limit = 50
	}

	// Built up rather than one query with optional predicates, because a partial index is
	// only used when the planner can see the constant.
	var (
		where = []string{"is_active", "status = 'published'"}
		args  []any
	)
	add := func(clause string, v any) {
		args = append(args, v)
		where = append(where, fmt.Sprintf(clause, len(args)))
	}
	if f.CEFRLevel != "" {
		add("cefr_level = $%d", f.CEFRLevel)
	}
	if f.Phoneme != "" {
		add("target_phonemes @> ARRAY[$%d]::text[]", f.Phoneme)
	}
	if f.Search != "" {
		add("lower(text) LIKE $%d", strings.ToLower(f.Search)+"%")
	}
	args = append(args, f.Limit, f.Offset)

	q := `SELECT ` + columns + ` FROM words WHERE ` + strings.Join(where, " AND ") +
		fmt.Sprintf(` ORDER BY text LIMIT $%d OFFSET $%d`, len(args)-1, len(args))

	rows, err := r.pool.Query(ctx, q, args...)
	if err != nil {
		return nil, fmt.Errorf("word: list: %w", err)
	}
	defer rows.Close()
	return collect(rows)
}

func (r *repository) Candidates(ctx context.Context, q CandidateQuery) ([]Word, error) {
	if q.Limit <= 0 || q.Limit > 100 {
		q.Limit = 20
	}
	if q.Seed == "" {
		q.Seed = "voca"
	}

	// Ordering, in priority order:
	//   1. commoner words first, when we know how common they are;
	//   2. then a hash of the word and the day, which is a shuffle that is STABLE for the
	//      day. Reopening the app mid-practice must deal the same hand, or a learner who
	//      closes the sheet loses their set (ARCHITECTURE.md 13.2).
	rows, err := r.pool.Query(ctx,
		`SELECT `+columns+`
		   FROM words
		  WHERE is_active AND status = 'published'
		    AND cefr_level = $1
		    AND NOT (id = ANY($2::uuid[]))
		  ORDER BY frequency_rank NULLS LAST, md5(id::text || $3)
		  LIMIT $4`,
		q.CEFRLevel, q.Exclude, q.Seed, q.Limit)
	if err != nil {
		return nil, fmt.Errorf("word: candidates: %w", err)
	}
	defer rows.Close()
	return collect(rows)
}

func (r *repository) Categories(ctx context.Context) ([]Category, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT c.id, c.slug, c.name_key, coalesce(c.icon, ''), c.sort_order,
		        (SELECT count(*) FROM words w WHERE w.category_id = c.id AND w.is_active)
		   FROM categories c
		  WHERE c.is_active
		  ORDER BY c.sort_order, c.slug`)
	if err != nil {
		return nil, fmt.Errorf("word: categories: %w", err)
	}
	defer rows.Close()

	out := []Category{}
	for rows.Next() {
		var c Category
		if err := rows.Scan(&c.ID, &c.Slug, &c.NameKey, &c.Icon, &c.SortOrder,
			&c.WordCount); err != nil {
			return nil, fmt.Errorf("word: scan category: %w", err)
		}
		out = append(out, c)
	}
	return out, rows.Err()
}

func collect(rows pgx.Rows) ([]Word, error) {
	out := []Word{}
	for rows.Next() {
		w, err := scan(rows)
		if err != nil {
			return nil, fmt.Errorf("word: scan: %w", err)
		}
		out = append(out, w)
	}
	return out, rows.Err()
}
