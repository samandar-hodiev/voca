// pronunciation/feedback: turns PronunciationError values into learner-facing Feedback.
//
// Produces MESSAGE KEYS AND PARAMETERS, never finished sentences. The Uzbek text lives in
// the app's ARB files, which is what makes a second interface language a translation task
// rather than a backend change.
//
// Each Feedback carries: related word, related phoneme, message key, articulation tip key
// (tongue, lips, airflow), and a priority for ordering on screen.
//
// Feedback is PERSISTED rather than regenerated, so a learner's history does not change
// retroactively when these rules improve.
//
// See ARCHITECTURE.md 6.3, 19.1.

package feedback

import (
	"sort"

	"github.com/samandar-hodiev/voca/backend/internal/pronunciation/domain"
)

// messageKeys maps a diagnosis to the sentence the app will render.
var messageKeys = map[domain.WordErrorType]string{
	domain.ErrorMispronunciation: "feedback.mispronunciation",
	domain.ErrorOmission:         "feedback.omission",
	domain.ErrorInsertion:        "feedback.insertion",
	domain.ErrorUnexpectedBreak:  "feedback.unexpected_break",
	domain.ErrorMissingBreak:     "feedback.missing_break",
	domain.ErrorMonotone:         "feedback.monotone",
}

// tipKeys maps a sound to how it is physically made. These are the sounds Uzbek speakers
// most often need help with in English; anything not listed gets no tip rather than a
// generic one, because a tip that says nothing is worse than silence.
var tipKeys = map[string]string{
	"θ":  "tip.tongue_between_teeth",
	"ð":  "tip.tongue_between_teeth_voiced",
	"w":  "tip.round_lips",
	"v":  "tip.teeth_on_lip",
	"r":  "tip.curl_tongue_back",
	"l":  "tip.tongue_tip_to_ridge",
	"ŋ":  "tip.back_of_tongue",
	"æ":  "tip.open_jaw_wide",
	"ɪ":  "tip.short_relaxed_vowel",
	"iː": "tip.long_tense_vowel",
}

// severityPriority orders what the learner reads first. Lower sorts first.
var severityPriority = map[domain.Severity]int{
	domain.SeveritySevere:   10,
	domain.SeverityModerate: 50,
	domain.SeverityMinor:    100,
}

type Generator struct {
	// MaxItems caps how much advice one attempt produces. Three things to fix is a
	// lesson; ten is a scolding.
	MaxItems int
}

func New() *Generator { return &Generator{MaxItems: 3} }

// Generate turns diagnoses into advice, most important first.
//
// Phoneme-level advice outranks word-level advice of the same severity: "your θ is the
// problem" is actionable, "the word was wrong" is not.
func (g *Generator) Generate(errs []domain.PronunciationError) []domain.Feedback {
	items := make([]domain.Feedback, 0, len(errs))

	for _, e := range errs {
		messageKey, ok := messageKeys[e.Type]
		if !ok {
			continue
		}

		priority := severityPriority[e.Severity]
		if priority == 0 {
			priority = 100
		}
		if e.Phoneme != "" {
			priority -= 5
		}

		items = append(items, domain.Feedback{
			Word:       e.Word,
			Phoneme:    e.Phoneme,
			MessageKey: messageKey,
			TipKey:     tipKeys[e.Phoneme],
			Priority:   priority,
		})
	}

	sort.SliceStable(items, func(i, j int) bool {
		return items[i].Priority < items[j].Priority
	})

	items = dedupe(items)
	if g.MaxItems > 0 && len(items) > g.MaxItems {
		items = items[:g.MaxItems]
	}
	return items
}

// dedupe keeps one piece of advice per word-and-sound. The analyzer can report the same
// sound from two angles, and saying it twice makes the app look broken.
func dedupe(items []domain.Feedback) []domain.Feedback {
	type key struct{ word, phoneme, message string }
	seen := make(map[key]bool, len(items))
	out := items[:0]
	for _, it := range items {
		k := key{it.Word, it.Phoneme, it.MessageKey}
		if seen[k] {
			continue
		}
		seen[k] = true
		out = append(out, it)
	}
	return out
}
