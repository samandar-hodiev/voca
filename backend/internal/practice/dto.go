// practice: request and response shapes for the HTTP API.
//
// Field names are snake_case per ARCHITECTURE.md 11.1. Words are embedded in the session
// response rather than referenced by id: the practice screen needs the text, the IPA and
// the focus sound to render a single item, and a second round trip per word would make
// opening the day's set N+1 requests.
//
// See ARCHITECTURE.md 11.2.

package practice

import "time"

type sessionResponse struct {
	ID     string `json:"id"`
	Type   string `json:"type"`
	Status string `json:"status"`

	ItemCount          int      `json:"item_count"`
	CompletedItemCount int      `json:"completed_item_count"`
	AverageScore       *float64 `json:"average_score"`

	// PassScore is sent so the app can say "you need 80" without a second copy of the
	// number drifting from the server's.
	PassScore float64 `json:"pass_score"`
	Passed    bool    `json:"passed"`

	PracticeDay string `json:"practice_day"`
	StartedAt   string `json:"started_at"`

	Items []itemResponse `json:"items"`
}

type itemResponse struct {
	ID       string `json:"id"`
	Position int    `json:"position"`
	Status   string `json:"status"`

	WordID         string   `json:"word_id"`
	Text           string   `json:"text"`
	PhoneticIPA    string   `json:"phonetic_ipa"`
	TargetPhonemes []string `json:"target_phonemes"`
	FocusSound     string   `json:"focus_sound"`
	CEFRLevel      string   `json:"cefr_level"`
	MeaningUz      string   `json:"meaning_uz,omitempty"`

	BestScore    *float64 `json:"best_score"`
	AttemptCount int      `json:"attempt_count"`
}

type dayResponse struct {
	Day      string `json:"day"`
	Status   string `json:"status"`
	Unlocked bool   `json:"unlocked"`

	WordCount      int      `json:"word_count"`
	CompletedCount int      `json:"completed_count"`
	AverageScore   *float64 `json:"average_score"`
}

func toSessionResponse(s Session, passScore float64) sessionResponse {
	items := make([]itemResponse, 0, len(s.Items))
	for _, it := range s.Items {
		phonemes := it.Word.TargetPhonemes
		if phonemes == nil {
			phonemes = []string{}
		}
		items = append(items, itemResponse{
			ID:             it.ID.String(),
			Position:       it.Position,
			Status:         it.Status,
			WordID:         it.WordID.String(),
			Text:           it.Word.Text,
			PhoneticIPA:    it.Word.PhoneticIPA,
			TargetPhonemes: phonemes,
			FocusSound:     it.Word.FocusSound(),
			CEFRLevel:      it.Word.CEFRLevel,
			MeaningUz:      it.Word.MeaningUz,
			BestScore:      it.BestScore,
			AttemptCount:   it.AttemptCount,
		})
	}

	return sessionResponse{
		ID:                 s.ID.String(),
		Type:               s.Type,
		Status:             s.Status,
		ItemCount:          s.ItemCount,
		CompletedItemCount: s.CompletedItemCount,
		AverageScore:       s.AverageScore,
		PassScore:          passScore,
		Passed:             s.Passed(passScore),
		PracticeDay:        s.PracticeDay.Format("2006-01-02"),
		StartedAt:          s.StartedAt.UTC().Format(time.RFC3339),
		Items:              items,
	}
}

func toDayResponses(days []Day) []dayResponse {
	out := make([]dayResponse, 0, len(days))
	for _, d := range days {
		out = append(out, dayResponse{
			Day:            d.Day.Format("2006-01-02"),
			Status:         d.Status,
			Unlocked:       d.Unlocked,
			WordCount:      d.WordCount,
			CompletedCount: d.CompletedCount,
			AverageScore:   d.AverageScore,
		})
	}
	return out
}
