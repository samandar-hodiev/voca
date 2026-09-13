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
	// Severe and Moderate split how bad a problem is.
	Severe   float64
	Moderate float64
	// MaxPhonemeErrors caps how many sounds are reported for one attempt: a learner who
	// gets everything wrong needs the worst three, not a wall of red.
	MaxPhonemeErrors int
}

func DefaultThresholds() Thresholds {
	return Thresholds{
		WordProblem:      60,
		PhonemeProblem:   60,
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
// Only sounds inside a word that already has a problem are reported: a single low phoneme
// in an otherwise well-pronounced word is usually the model being uncertain, not the
// learner being wrong, and chasing it teaches nothing.
func (a *Analyzer) phonemeErrors(out domain.AssessmentOutput) []domain.PronunciationError {
	type candidate struct {
		err      domain.PronunciationError
		accuracy float64
	}
	var found []candidate

	for _, w := range out.Words {
		wordHasProblem := w.Accuracy < a.t.WordProblem ||
			(w.Error != domain.ErrorNone && w.Error != "")
		if !wordHasProblem {
			continue
		}
		for _, p := range w.Phonemes {
			if p.Accuracy >= a.t.PhonemeProblem {
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
