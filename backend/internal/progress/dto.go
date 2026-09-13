// progress: request and response shapes for the HTTP API.
//
// Kept separate from domain models on purpose: the wire contract and the domain evolve
// independently. Field names are snake_case per ARCHITECTURE.md 11.1.
//
// See ARCHITECTURE.md 11.2.

package progress

// summaryResponse is the whole Progress dashboard in one read.
type summaryResponse struct {
	OverallScore   int `json:"overall_score"`
	ScoreDelta     int `json:"score_delta"`
	WordsPracticed int `json:"words_practiced"`
	StreakDays     int `json:"streak_days"`
	BestStreak     int `json:"best_streak"`

	Week       []dayResponse       `json:"week"`
	WeakSounds []weakSoundResponse `json:"weak_sounds"`
	Recent     []recentResponse    `json:"recent"`
}

type dayResponse struct {
	// A plain date, not an instant: which day it is has already been decided in the
	// learner's own timezone, and sending a timestamp would invite the app to decide again.
	Day   string `json:"day"`
	Words int    `json:"words"`
	Goal  int    `json:"goal"`
}

type weakSoundResponse struct {
	Phoneme  string `json:"phoneme"`
	Example  string `json:"example"`
	Accuracy int    `json:"accuracy"`
}

type recentResponse struct {
	Word  string `json:"word"`
	Score int    `json:"score"`
	At    string `json:"at"`
}

func toSummaryResponse(s Summary) summaryResponse {
	week := make([]dayResponse, 0, len(s.Week))
	for _, d := range s.Week {
		week = append(week, dayResponse{
			Day:   d.Day.Format("2006-01-02"),
			Words: d.Words,
			Goal:  d.Goal,
		})
	}

	weak := make([]weakSoundResponse, 0, len(s.WeakSounds))
	for _, w := range s.WeakSounds {
		weak = append(weak, weakSoundResponse{
			Phoneme:  w.Phoneme,
			Example:  w.Example,
			Accuracy: w.Accuracy,
		})
	}

	recent := make([]recentResponse, 0, len(s.Recent))
	for _, r := range s.Recent {
		recent = append(recent, recentResponse{
			Word:  r.Word,
			Score: r.Score,
			At:    r.At.UTC().Format("2006-01-02T15:04:05Z"),
		})
	}

	return summaryResponse{
		OverallScore:   s.OverallScore,
		ScoreDelta:     s.ScoreDelta,
		WordsPracticed: s.WordsPracticed,
		StreakDays:     s.StreakDays,
		BestStreak:     s.BestStreak,
		Week:           week,
		WeakSounds:     weak,
		Recent:         recent,
	}
}
