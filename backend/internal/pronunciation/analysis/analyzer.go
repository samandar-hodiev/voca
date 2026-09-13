// pronunciation/analysis: derives PronunciationError values from word and phoneme results.
//
// Classifies each problem as mispronunciation, omission, insertion, unexpected_break,
// missing_break, or monotone, and assigns severity (minor, moderate, severe).
//
// These are OUR diagnoses, computed from normalized scores — not vendor fields copied
// through. Changing how errors are detected must not require touching the Azure adapter.
//
// See ARCHITECTURE.md 6.2, 6.3.

package analysis

import (
	"sort"

	"github.com/samandar-hodiev/voca/backend/internal/pronunciation/domain"
)

// Thresholds decide when a score becomes a diagnosis. Passed in rather than hardcoded, so
// the line between "fine" and "needs work" can move without a code change.
type Thresholds struct {
	// WordProblem is the accuracy below which a word counts as mispronounced.
	WordProblem float64
	// PhonemeProblem is the accuracy below which a single sound is called out.
	PhonemeProblem float64
	// PhonemeAlways is the accuracy below which a sound is called out even when the word
	// around it scored well. See phonemeErrors for why the two bars differ.
	PhonemeAlways float64
	// Severe and Moderate split how bad a problem is.
	Severe   float64
	Moderate float64
	// MaxPhonemeErrors caps how many sounds are reported for one attempt: a learner who
	// gets everything wrong needs the worst three, not a wall of red.
	MaxPhonemeErrors int
}

// DefaultThresholds puts the bar for "needs work" at 80.
//
// It used to be 60, which meant a learner could finish an attempt scoring 72 and be told
// nothing at all — a number with no lesson attached. 80 is the same line the app already
// draws when it colours a score green, so the advice and the colour now agree.
//
// The severity bands stay where they were: below 40 is severe, 40 to 60 moderate, and the
// new 60-to-80 range is minor. A word at 72 is worth a note, not an alarm.
func DefaultThresholds() Thresholds {
	return Thresholds{
		WordProblem:      80,
		PhonemeProblem:   80,
		PhonemeAlways:    40,
		Severe:           40,
		Moderate:         60,
		MaxPhonemeErrors: 3,
	}
}

type Analyzer struct{ t Thresholds }

func New(t Thresholds) *Analyzer { return &Analyzer{t: t} }

// Analyze turns the assessed words into the problems worth telling a learner about.
//
// Word-level problems come first because they are what the learner notices; the phoneme
// problems that explain them follow, worst first and capped.
func (a *Analyzer) Analyze(out domain.AssessmentOutput) []domain.PronunciationError {
	var errs []domain.PronunciationError

	for _, w := range out.Words {
		switch {
		case w.Error != domain.ErrorNone && w.Error != "":
			errs = append(errs, domain.PronunciationError{
				Word:     w.Word,
				Type:     w.Error,
				Severity: a.severity(w.Accuracy),
			})
		case w.Accuracy < a.t.WordProblem:
			// The provider did not label it, but our own bar says this is a problem.
			errs = append(errs, domain.PronunciationError{
				Word:     w.Word,
				Type:     domain.ErrorMispronunciation,
				Severity: a.severity(w.Accuracy),
			})
		}
	}

	errs = append(errs, a.phonemeErrors(out)...)
	return errs
}

// phonemeErrors finds the individual sounds that went wrong, worst first.
//
// Two bars, not one. A merely weak sound is reported only inside a word that already has
// a problem: a 74 in a word that scored 92 is usually the model being uncertain rather
// than the learner being wrong, and chasing it teaches nothing. Measured evidence for
// that caution — a correctly spoken "think" came back with its final k at 31 purely
// because the recording clipped.
//
// But silence has a cost too. A sound scoring in the thirties inside a word that passed
// is the one thing a learner would most want to know, and refusing to mention it is how
// somebody keeps making the same mistake at 85. So anything below PhonemeAlways is
// reported whatever the word did.
func (a *Analyzer) phonemeErrors(out domain.AssessmentOutput) []domain.PronunciationError {
	type candidate struct {
		err      domain.PronunciationError
		accuracy float64
	}
	var found []candidate

	for _, w := range out.Words {
		wordHasProblem := w.Accuracy < a.t.WordProblem ||
			(w.Error != domain.ErrorNone && w.Error != "")
		for _, p := range w.Phonemes {
			if p.Accuracy >= a.t.PhonemeProblem {
				continue
			}
			if !wordHasProblem && p.Accuracy >= a.t.PhonemeAlways {
				continue
			}
			found = append(found, candidate{
				err: domain.PronunciationError{
					Word:     w.Word,
					Phoneme:  p.Phoneme,
					Type:     domain.ErrorMispronunciation,
					Severity: a.severity(p.Accuracy),
				},
				accuracy: p.Accuracy,
			})
		}
	}

	sort.SliceStable(found, func(i, j int) bool {
		return found[i].accuracy < found[j].accuracy
	})

	limit := a.t.MaxPhonemeErrors
	if limit > 0 && len(found) > limit {
		found = found[:limit]
	}

	out2 := make([]domain.PronunciationError, 0, len(found))
	for _, c := range found {
		out2 = append(out2, c.err)
	}
	return out2
}

func (a *Analyzer) severity(accuracy float64) domain.Severity {
	switch {
	case accuracy < a.t.Severe:
		return domain.SeveritySevere
	case accuracy < a.t.Moderate:
		return domain.SeverityModerate
	default:
		return domain.SeverityMinor
	}
}
