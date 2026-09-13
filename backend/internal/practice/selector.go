// practice: PracticeSelector — chooses which content a session contains.
//
//	PracticeSelector.Select(ctx, userID, criteria) -> []Word
//
// MVP strategy: filter by learning language, accent, active status, and the user's
// difficulty; exclude words recently practised well; prefer higher frequency_rank; shuffle
// deterministically per day so daily practice is stable if the app is reopened.
//
// This interface is the seam for the whole personalization roadmap. Adaptive difficulty,
// spaced repetition, and weak-sound targeting are NEW IMPLEMENTATIONS of this interface,
// selected by configuration — not edits to sessions, items, attempts, or the app.
//
// See ARCHITECTURE.md 13.2, 15.4, 34.

package practice

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"

	"github.com/samandar-hodiev/voca/backend/internal/word"
)

// Criteria is what a session is being built for.
type Criteria struct {
	CEFRLevel string
	Count     int
	Day       time.Time

	// Exclude are words this learner has already passed. Passed on by the caller, because
	// that history belongs to this module rather than to content.
	Exclude []uuid.UUID
}

type Selector interface {
	Select(ctx context.Context, userID uuid.UUID, c Criteria) ([]word.Word, error)
}

// Content is the port onto the word module. Declared here, by the consumer, so this
// module depends on a question rather than on a package (ARCHITECTURE.md 5.5).
type Content interface {
	Candidates(ctx context.Context, q word.CandidateQuery) ([]word.Word, error)
}

// LevelSelector is the MVP strategy: the learner's own level, commonest words first,
// shuffled stably within the day.
type LevelSelector struct{ content Content }

func NewLevelSelector(content Content) *LevelSelector {
	return &LevelSelector{content: content}
}

func (s *LevelSelector) Select(
	ctx context.Context, userID uuid.UUID, c Criteria,
) ([]word.Word, error) {
	// The seed ties the shuffle to this learner and this day. Same person, same day, same
	// set — so closing the app mid-practice does not deal a different hand. A different
	// day, or a different person, gets a different one.
	seed := fmt.Sprintf("%s:%s", userID, c.Day.Format("2006-01-02"))

	return s.content.Candidates(ctx, word.CandidateQuery{
		CEFRLevel: c.CEFRLevel,
		Exclude:   c.Exclude,
		Seed:      seed,
		Limit:     c.Count,
	})
}
