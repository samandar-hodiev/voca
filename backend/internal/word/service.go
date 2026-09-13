// word: business logic / use cases. Content lookup and candidate selection.
//
// Responsibility: all business rules for this module, resource-ownership checks,
// orchestration across repositories and provider ports, and transaction boundaries.
//
// This is the module's PUBLIC SURFACE. Other modules may call this service interface and
// nothing else — never this module's repository, models, or tables (ARCHITECTURE.md 5.5).
//
// MUST NOT import: gin, pgx or sql types, or any vendor SDK.
//
// See ARCHITECTURE.md 13.4, 5.3, 5.5.

package word

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"strings"

	"github.com/google/uuid"

	"github.com/samandar-hodiev/voca/backend/internal/shared/apperr"
)

// validLevels mirrors the CHECK constraint. Validating here as well means a bad filter is
// a 400 with a useful message rather than an empty list that looks like missing content.
var validLevels = map[string]bool{
	"A1": true, "A2": true, "B1": true, "B2": true, "C1": true, "C2": true,
}

type Service struct {
	repo Repository
	log  *slog.Logger
}

func NewService(repo Repository, log *slog.Logger) *Service {
	return &Service{repo: repo, log: log}
}

func (s *Service) Get(ctx context.Context, id uuid.UUID) (Word, error) {
	w, err := s.repo.ByID(ctx, id)
	if errors.Is(err, ErrNotFound) {
		return Word{}, apperr.NotFound("Bunday so‘z topilmadi.")
	}
	if err != nil {
		return Word{}, apperr.Internal(err)
	}
	return w, nil
}

func (s *Service) List(ctx context.Context, f Filter) ([]Word, error) {
	f.CEFRLevel = strings.ToUpper(strings.TrimSpace(f.CEFRLevel))
	if f.CEFRLevel != "" && !validLevels[f.CEFRLevel] {
		return nil, apperr.Validation("Bunday daraja yo‘q.")
	}

	words, err := s.repo.List(ctx, f)
	if err != nil {
		return nil, apperr.Internal(err)
	}
	return words, nil
}

// Candidates answers the practice module's question: which words could this session use.
//
// The caller decides how many and which to leave out; this module decides nothing about
// somebody's practice, only about content.
func (s *Service) Candidates(ctx context.Context, q CandidateQuery) ([]Word, error) {
	q.CEFRLevel = strings.ToUpper(strings.TrimSpace(q.CEFRLevel))
	if !validLevels[q.CEFRLevel] {
		return nil, apperr.New(apperr.CodeValidation, http.StatusBadRequest,
			"Mashq uchun daraja aniqlanmadi.")
	}
	if q.Exclude == nil {
		q.Exclude = []uuid.UUID{}
	}

	words, err := s.repo.Candidates(ctx, q)
	if err != nil {
		return nil, apperr.Internal(err)
	}
	return words, nil
}

func (s *Service) Categories(ctx context.Context) ([]Category, error) {
	cats, err := s.repo.Categories(ctx)
	if err != nil {
		return nil, apperr.Internal(err)
	}
	return cats, nil
}
