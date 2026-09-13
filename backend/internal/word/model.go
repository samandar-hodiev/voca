// word: domain entities.
//
// Plain Go structs expressing this module's business concepts. Independent of transport
// (JSON/HTTP), of storage (database row shapes), and of any external provider payload.
//
// See ARCHITECTURE.md 13.4 and 10.2 (tables backing these entities).

package word

import "github.com/google/uuid"

// Word is one practice unit: the thing a learner is asked to say.
type Word struct {
	ID   uuid.UUID
	Text string

	Language string
	Accent   string

	PhoneticIPA        string
	PhoneticRespelling string

	// TargetPhonemes are the sounds this word exercises, in IPA. What makes weak-sound
	// practice possible: "find me words that drill θ" is an index lookup, not a scan.
	TargetPhonemes []string

	AudioURL        string
	CategoryID      *uuid.UUID
	DifficultyLevel string
	CEFRLevel       string
	PartOfSpeech    string
	MeaningUz       string
	ExampleSentence string

	// FrequencyRank is lower for commoner words, and nil when we do not know. Absent for
	// every row today: no frequency source with a commercial licence was found, and a
	// made-up rank is worse than no rank (docs/DATA_SOURCES.md).
	FrequencyRank *int
}

// FocusSound is the one sound to show next to the word.
//
// The sounds are stored sorted, so this is stable rather than arbitrary; the app shows one
// symbol and a learner should see the same one each time they meet the word.
func (w Word) FocusSound() string {
	if len(w.TargetPhonemes) == 0 {
		return ""
	}
	return w.TargetPhonemes[0]
}

// Category groups words thematically. None are seeded yet: the MVP selects by level, and
// an empty category list is an honest answer rather than an invented one.
type Category struct {
	ID        uuid.UUID
	Slug      string
	NameKey   string
	Icon      string
	SortOrder int
	WordCount int
}

// CandidateQuery asks for words a session could be built from.
//
// The practice module owns the STRATEGY and this module owns the DATA, so what crosses the
// boundary is a query rather than a decision (ARCHITECTURE.md 5.5, 13.2).
type CandidateQuery struct {
	CEFRLevel string

	// Exclude keeps words out that the caller has already used — its own history, which
	// this module has no business reading.
	Exclude []uuid.UUID

	// Seed makes the shuffle deterministic, so reopening the app mid-practice does not
	// deal a different hand (ARCHITECTURE.md 13.2).
	Seed  string
	Limit int
}

// Filter is the public word list, as GET /api/v1/words exposes it.
type Filter struct {
	CEFRLevel string
	Phoneme   string
	Search    string
	Limit     int
	Offset    int
}
