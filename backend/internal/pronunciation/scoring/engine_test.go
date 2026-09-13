// The scoring policy, pinned to numbers measured against the live service.
//
// Every case here is a real Azure response recorded while diagnosing a learner's report
// that saying "what" for "wooded" scored 92. They are the reason the policy changed, so
// they are the reason it must not change back.

package scoring

import (
	"testing"

	"github.com/samandar-hodiev/voca/backend/internal/pronunciation/domain"
)

// attempt builds a single-word signal with the given phoneme scores.
func attempt(accuracy, fluency, completeness float64, phonemes ...float64) domain.AssessmentOutput {
	ph := make([]domain.PhonemeAssessment, 0, len(phonemes))
	for i, s := range phonemes {
		ph = append(ph, domain.PhonemeAssessment{Phoneme: string(rune('a' + i)), Accuracy: s})
	}
	return domain.AssessmentOutput{
		Accuracy: accuracy, Fluency: fluency, Completeness: completeness,
		Words: []domain.WordAssessment{{Word: "w", Accuracy: accuracy, Phonemes: ph}},
	}
}

func engine() *Engine { return New(DefaultWeights()) }

func TestSayingTheWrongWordNoLongerScoresLikeSuccess(t *testing.T) {
	// Measured: reference "three", learner said "tree". Under v1 this was 93 — a pass.
	got := engine().Score(attempt(86, 100, 100, 48, 78, 100))

	if got.Overall > 60 {
		t.Errorf("overall = %v, want it capped at or below 60 — 'tree' is not 'three'",
			got.Overall)
	}
	// The dimensions themselves are still reported honestly.
	if got.Fluency != 100 {
		t.Errorf("fluency = %v, want the provider's 100 passed through", got.Fluency)
	}
}

func TestOtherMeasuredNearMissesAlsoFail(t *testing.T) {
	cases := []struct {
		name                            string
		accuracy, fluency, completeness float64
		phonemes                        []float64
	}{
		{"world said as word", 80, 100, 100, []float64{100, 82, 46, 27}},
		{"rarely said as really", 68, 100, 100, []float64{44, 1, 87, 100}},
		{"wooded said as what", 41, 0, 0, []float64{43, 30, 0, 0, 48}},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			got := engine().Score(attempt(c.accuracy, c.fluency, c.completeness, c.phonemes...))
			if got.Overall > 60 {
				t.Errorf("overall = %v, want 60 or less", got.Overall)
			}
		})
	}
}

func TestARealAttemptStillScoresWell(t *testing.T) {
	// Measured: "water" said correctly. Worst sound 94, comfortably above the floor.
	got := engine().Score(attempt(98, 100, 100, 100, 100, 100, 94))

	if got.Overall < 95 {
		t.Errorf("overall = %v, want a correct word to score high", got.Overall)
	}
}

func TestAPerfectAttemptIsUnaffected(t *testing.T) {
	got := engine().Score(attempt(100, 100, 100, 100, 100, 100))
	if got.Overall != 100 {
		t.Errorf("overall = %v, want 100", got.Overall)
	}
}

func TestOneWordIsScoredOnAccuracyAlone(t *testing.T) {
	// Fluency is rhythm, and one word has none. A learner whose single word was accurate
	// should not be dragged down by a dimension that says nothing about it.
	got := engine().Score(attempt(90, 0, 100, 90, 90))

	if got.Overall != 90 {
		t.Errorf("overall = %v, want 90 — fluency must not count for a single word",
			got.Overall)
	}
}

func TestSeveralWordsStillUseTheBlend(t *testing.T) {
	// Sentence practice does not exist yet, but the policy for it must not have silently
	// become accuracy-only along the way.
	out := domain.AssessmentOutput{
		Accuracy: 80, Fluency: 60, Completeness: 100,
		Words: []domain.WordAssessment{{Word: "a"}, {Word: "b"}},
	}
	got := engine().Score(out)

	want := 80*0.5 + 60*0.3 + 100*0.2 // 78
	if got.Overall != want {
		t.Errorf("overall = %v, want %v", got.Overall, want)
	}
}

func TestTheFloorDoesNotApplyToSentences(t *testing.T) {
	// One weak sound among many is ordinary in a sentence; capping the whole utterance for
	// it would punish a good attempt.
	out := domain.AssessmentOutput{
		Accuracy: 90, Fluency: 90, Completeness: 100,
		Words: []domain.WordAssessment{
			{Word: "a", Phonemes: []domain.PhonemeAssessment{{Phoneme: "x", Accuracy: 10}}},
			{Word: "b", Phonemes: []domain.PhonemeAssessment{{Phoneme: "y", Accuracy: 95}}},
		},
	}
	if got := engine().Score(out); got.Overall < 80 {
		t.Errorf("overall = %v, want the sentence blend, not the single-word cap", got.Overall)
	}
}

func TestAProviderWithoutPhonemesCannotTripTheFloor(t *testing.T) {
	out := domain.AssessmentOutput{
		Accuracy: 95, Fluency: 100, Completeness: 100,
		Words: []domain.WordAssessment{{Word: "w"}},
	}
	if got := engine().Score(out); got.Overall != 95 {
		t.Errorf("overall = %v, want 95", got.Overall)
	}
}

func TestThePolicyVersionMovedWithThePolicy(t *testing.T) {
	// Every attempt stores this. If the numbers change and the version does not, a row
	// written yesterday and one written today become impossible to tell apart.
	if got := engine().Version(); got != "v2" {
		t.Errorf("version = %q, want v2", got)
	}
}
