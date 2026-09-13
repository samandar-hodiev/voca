// practice: domain entities.
//
// Plain Go structs expressing this module's business concepts. Independent of transport
// (JSON/HTTP), of storage (database row shapes), and of any external provider payload.
//
// See ARCHITECTURE.md 13 and 10.3 (tables backing these entities).

package practice

import (
	"time"

	"github.com/google/uuid"

	"github.com/samandar-hodiev/voca/backend/internal/word"
)

// Session types and statuses mirror the CHECK constraints in the schema.
const (
	TypeDaily = "daily"

	StatusInProgress = "in_progress"
	StatusCompleted  = "completed"
	StatusAbandoned  = "abandoned"

	ItemPending   = "pending"
	ItemAttempted = "attempted"
	ItemCompleted = "completed"
)

// Session is one sitting of practice. The day's set is a session of type daily; there is
// no separate "daily list" concept, because a day of practice is exactly a session
// (ARCHITECTURE.md 13.1).
type Session struct {
	ID     uuid.UUID
	UserID uuid.UUID

	Type        string
	ContentType string
	Status      string

	ItemCount          int
	CompletedItemCount int

	// AverageScore is nil until the session is completed. It is what the next day is
	// locked behind.
	AverageScore *float64

	// PracticeDay is the learner's local date this session belongs to.
	PracticeDay time.Time

	StartedAt   time.Time
	CompletedAt *time.Time

	Items []Item
}

// Passed reports whether this session cleared the bar that opens the next day.
func (s Session) Passed(threshold float64) bool {
	return s.Status == StatusCompleted &&
		s.AverageScore != nil && *s.AverageScore >= threshold
}

// Item is one word inside a session.
type Item struct {
	ID       uuid.UUID
	WordID   uuid.UUID
	Position int
	Status   string

	// BestScore is the highest this word has scored in this session. Retries are
	// unlimited, so what counts is the best attempt rather than the last.
	BestScore     *float64
	BestAttemptID *uuid.UUID
	AttemptCount  int

	Word word.Word
}

// Day is one square in the week view: what the learner sees before they open anything.
type Day struct {
	Day    time.Time
	Status string

	// Unlocked days can be practised today. Exactly one day is ever unlocked, because the
	// point of the lock is to stop somebody racing ahead of their own pronunciation.
	Unlocked bool

	WordCount      int
	CompletedCount int
	AverageScore   *float64
}

// Week statuses, as the app renders them.
const (
	DayLocked     = "locked"
	DayAvailable  = "available"
	DayInProgress = "in_progress"
	DayPassed     = "passed"
	DayFailed     = "failed"
)
