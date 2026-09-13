// Where the line between "fine" and "needs work" sits, and what falls on each side.
//
// This is the file that decides whether a learner is told anything at all, so the cases
// worth pinning are the two edges: an attempt that used to pass in silence, and a sound
// low enough to mention even when the word around it went well.

package analysis

import (
	"testing"

	"github.com/samandar-hodiev/voca/backend/internal/pronunciation/domain"
)

func word(w string, accuracy float64, phonemes ...domain.PhonemeAssessment) domain.AssessmentOutput {
	return domain.AssessmentOutput{
		Words: []domain.WordAssessment{{
			Word: w, Accuracy: accuracy, Error: domain.ErrorNone, Phonemes: phonemes,
		}},
	}
}

func ph(symbol string, accuracy float64) domain.PhonemeAssessment {
	return domain.PhonemeAssessment{Phoneme: symbol, Accuracy: accuracy}
}

func TestAWordInTheSeventiesIsNowWorthMentioning(t *testing.T) {
	// The old bar was 60, so this attempt produced a score and no lesson.
	got := New(DefaultThresholds()).Analyze(word("think", 72))

	if len(got) == 0 {
		t.Fatal("a word at 72 produced no advice")
	}
	if got[0].Type != domain.ErrorMispronunciation {
		t.Errorf("type = %q, want mispronunciation", got[0].Type)
	}
	if got[0].Severity != domain.SeverityMinor {
		t.Errorf("severity = %q, want minor — 72 is a note, not an alarm", got[0].Severity)
	}
}

func TestAGoodWordStaysSilent(t *testing.T) {
	if got := New(DefaultThresholds()).Analyze(word("think", 94, ph("θ", 96))); len(got) != 0 {
		t.Errorf("a word at 94 produced %d pieces of advice, want none", len(got))
	}
}

func TestABadSoundIsNamedEvenInsideAGoodWord(t *testing.T) {
	// Measured case: "think" scored 94 with its final k at 31. Saying nothing is how
	// somebody keeps making the same mistake at 85.
	got := New(DefaultThresholds()).Analyze(word("think", 94, ph("θ", 96), ph("k", 31)))

	if len(got) != 1 {
		t.Fatalf("advice = %d items, want 1", len(got))
	}
	if got[0].Phoneme != "k" {
		t.Errorf("phoneme = %q, want k", got[0].Phoneme)
	}
	if got[0].Severity != domain.SeveritySevere {
		t.Errorf("severity = %q, want severe", got[0].Severity)
	}
}

func TestAMerelyWeakSoundInAGoodWordIsIgnored(t *testing.T) {
	// A 74 inside a word that scored 92 is usually the model being uncertain. Reporting
	// it would teach a lesson that is not there.
	if got := New(DefaultThresholds()).Analyze(word("think", 92, ph("ɪ", 74))); len(got) != 0 {
		t.Errorf("a marginal sound in a good word produced %d items, want none", len(got))
	}
}

func TestWeakSoundsAreReportedOnceTheWordItselfIsWeak(t *testing.T) {
	got := New(DefaultThresholds()).Analyze(word("think", 58, ph("θ", 41), ph("ɪ", 74)))

	var phonemes []string
	for _, e := range got {
		if e.Phoneme != "" {
			phonemes = append(phonemes, e.Phoneme)
		}
	}
	if len(phonemes) != 2 {
		t.Fatalf("phoneme advice = %v, want both θ and ɪ", phonemes)
	}
	// Worst first: that is the one to practise.
	if phonemes[0] != "θ" {
		t.Errorf("first phoneme = %q, want θ", phonemes[0])
	}
}

func TestTheWorstThreeSoundsAreEnough(t *testing.T) {
	got := New(DefaultThresholds()).Analyze(word("strength", 40,
		ph("s", 30), ph("t", 25), ph("r", 20), ph("ŋ", 15), ph("θ", 10)))

	var phonemes int
	for _, e := range got {
		if e.Phoneme != "" {
			phonemes++
		}
	}
	if phonemes != 3 {
		t.Errorf("phoneme advice = %d items, want 3 — a wall of red is not a lesson", phonemes)
	}
}
