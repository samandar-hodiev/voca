// pronunciation/scoring: ScoringEngine — turns a provider signal into Voca scores.
//
// PRINCIPLE: the provider gives us a SIGNAL, not the truth. Azure's numbers come from a
// model we do not control, tuned on speakers who may not resemble Uzbek learners, over
// audio from phone microphones of varying quality. This engine is where scoring POLICY
// lives so that our core metric stays ours.
//
// v2 policy, and why it changed. A learner said "what" when asked for "wooded" and was
// given 92. Measured against the live service, the cause was in our arithmetic rather than
// the vendor's:
//
//	etalon three  said tree    accuracy 86  fluency 100  completeness 100  -> old overall 93
//	etalon world  said word    accuracy 80  fluency 100  completeness 100  -> old overall 90
//	etalon rarely said really  accuracy 68  fluency 100  completeness 100  -> old overall 84
//
// Fluency measures rhythm, pauses and rate. Completeness measures whether the reference was
// covered. NEITHER CAN TELL WHICH WORD WAS SAID, and together they were half the score — so
// any utterance the engine managed to align onto the reference collected 50 free points.
//
// Two changes follow:
//
//  1. A single word is scored on accuracy alone. There is no rhythm in one word to measure,
//     so fluency is not evidence about it. Fluency returns when sentence practice does.
//
//  2. A phoneme floor. The word score is smoothed and forgiving; the phoneme scores are not,
//     and they separated every wrong word from every right one in the measurements above:
//
//     three -> tree    word 86, worst phoneme 48
//     world -> word    word 80, worst phoneme 27
//     rarely -> really word 68, worst phoneme  1
//     three -> three   word 100, worst phoneme 100
//     water -> water   word 98, worst phoneme 94
//
//     A word containing a sound this far down was not the word we asked for, whatever the
//     average says, so its overall is capped below the pass mark.
//
// The floor is set nearer the failing side than the midpoint on purpose. Telling somebody
// they got it wrong when they got it right is the more damaging mistake, and a real Uzbek
// accent will score lower on individual sounds than the synthetic speech these numbers came
// from. That caveat is the reason step 4 of the plan — a labelled set of real recordings —
// is not optional before these numbers are trusted.
//
// Rules that keep this evolvable:
//   - every attempt records Version, so old rows stay interpretable
//   - weights are a value passed in, never constants scattered in code
//   - a future calibrated or hybrid model is a new implementation behind the same call
//
// See ARCHITECTURE.md 6.4.

package scoring

import "github.com/samandar-hodiev/voca/backend/internal/pronunciation/domain"

// Weights decide how much each dimension contributes to the overall score.
type Weights struct {
	Accuracy     float64
	Fluency      float64
	Completeness float64
}

// DefaultWeights is the policy for an utterance of several words, where rhythm and coverage
// are real evidence about how it was said.
func DefaultWeights() Weights {
	return Weights{Accuracy: 0.5, Fluency: 0.3, Completeness: 0.2}
}

// SingleWordWeights is the policy for one word: accuracy is the only dimension that carries
// information about it.
func SingleWordWeights() Weights {
	return Weights{Accuracy: 1, Fluency: 0, Completeness: 0}
}

const (
	// DefaultPhonemeFloor is the sound score below which a word is treated as not having
	// been said, however well the word averaged.
	DefaultPhonemeFloor = 60

	// DefaultFloorCap is what such a word's overall is capped at. Below the daily pass
	// mark, so a word the learner did not really say cannot count towards their day.
	DefaultFloorCap = 60
)

// Engine applies a scoring policy. Its Version is stored on every attempt.
type Engine struct {
	weights      Weights
	singleWord   Weights
	phonemeFloor float64
	floorCap     float64
	version      string
}

func New(w Weights) *Engine {
	return &Engine{
		weights:      w,
		singleWord:   SingleWordWeights(),
		phonemeFloor: DefaultPhonemeFloor,
		floorCap:     DefaultFloorCap,
		version:      "v2",
	}
}

// Version identifies the policy that produced a score, so a row written today is still
// interpretable after the policy changes.
func (e *Engine) Version() string { return e.version }

// Score turns the provider's signal into Voca's numbers.
//
// Accuracy, fluency and completeness are passed through as the provider reported them —
// they are shown separately and must not be quietly rewritten. Only Overall is Voca's
// verdict, and only Overall carries the policy.
func (e *Engine) Score(out domain.AssessmentOutput) domain.Scores {
	accuracy := clamp(out.Accuracy)
	fluency := clamp(out.Fluency)
	completeness := clamp(out.Completeness)

	weights := e.weights
	if len(out.Words) == 1 {
		weights = e.singleWord
	}

	scores := domain.Scores{
		Accuracy:     accuracy,
		Fluency:      fluency,
		Completeness: completeness,
	}

	total := weights.Accuracy + weights.Fluency + weights.Completeness
	if total <= 0 {
		// A misconfigured weight set must not produce a silent zero for every learner.
		scores.Overall = accuracy
		return scores
	}

	overall := (accuracy*weights.Accuracy +
		fluency*weights.Fluency +
		completeness*weights.Completeness) / total

	// The floor applies to single words only. In a sentence, one weak sound among dozens
	// is ordinary; capping the whole utterance for it would punish a good attempt. Sentence
	// practice will need its own rule, and it does not exist yet.
	if len(out.Words) == 1 {
		if worst, ok := worstPhoneme(out); ok && worst < e.phonemeFloor && overall > e.floorCap {
			overall = e.floorCap
		}
	}

	scores.Overall = clamp(round1(overall))
	return scores
}

// worstPhoneme is the lowest sound score in the utterance, and whether there was one at all.
// A provider that reports no phonemes cannot trip the floor.
func worstPhoneme(out domain.AssessmentOutput) (float64, bool) {
	worst, found := 0.0, false
	for _, w := range out.Words {
		for _, p := range w.Phonemes {
			if !found || p.Accuracy < worst {
				worst, found = p.Accuracy, true
			}
		}
	}
	return worst, found
}

func clamp(v float64) float64 {
	switch {
	case v < 0:
		return 0
	case v > 100:
		return 100
	default:
		return v
	}
}

// round1 keeps one decimal: a score shown to a learner as 85.6 should be stored as 85.6,
// not as a float that renders differently on two screens.
func round1(v float64) float64 {
	return float64(int64(v*10+0.5)) / 10
}
