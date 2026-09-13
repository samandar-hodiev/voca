// progress: domain entities.
//
// Plain Go structs expressing this module's business concepts. Independent of transport
// (JSON/HTTP), of storage (database row shapes), and of any external provider payload.
//
// See ARCHITECTURE.md 14 and 10 (tables backing these entities).

package progress

import "time"

// Summary is everything the Progress dashboard shows.
type Summary struct {
	// OverallScore is the average of the last seven days, out of 100.
	OverallScore int

	// ScoreDelta compares that against the seven days before it, in points.
	ScoreDelta int

	// WordsPracticed counts distinct words ever attempted, not attempts: saying "think"
	// twenty times is one word learned, and a counter that disagrees feels like a lie.
	WordsPracticed int

	StreakDays int
	BestStreak int
	Week       []DailyCount
	WeakSounds []WeakSound
	Recent     []RecentAttempt
}

// DailyCount is one column of the week chart.
type DailyCount struct {
	Day   time.Time
	Words int
	Goal  int
}

// WeakSound is a sound this learner keeps getting wrong.
type WeakSound struct {
	Phoneme string

	// Example is a word they actually said it in, so the symbol means something to
	// somebody who cannot read IPA.
	Example  string
	Accuracy int
}

type RecentAttempt struct {
	Word  string
	Score int
	At    time.Time
}
