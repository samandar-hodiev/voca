// pronunciation/scoring: ScoringEngine — turns a provider signal into Voca scores.
//
// PRINCIPLE: the provider gives us a SIGNAL, not the truth. Azure's numbers come from a
// model we do not control, tuned on speakers who may not resemble Uzbek learners, over
// audio from phone microphones of varying quality. This engine is where scoring POLICY
// lives so that our core metric stays ours.
//
// MVP policy: accuracy, fluency and completeness pass through; overall is a weighted blend
// (0.5 accuracy, 0.3 fluency, 0.2 completeness) clamped to 0-100.
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

// DefaultWeights is the MVP policy. Accuracy dominates because it is what a learner came
// for; fluency matters next; completeness is a guard against reading half the word.
func DefaultWeights() Weights {
	return Weights{Accuracy: 0.5, Fluency: 0.3, Completeness: 0.2}
}

// Engine applies a scoring policy. Its Version is stored on every attempt.
type Engine struct {
	weights Weights
	version string
}

func New(w Weights) *Engine { return &Engine{weights: w, version: "v1"} }

// Version identifies the policy that produced a score, so a row written today is still
// interpretable after the policy changes.
func (e *Engine) Version() string { return e.version }

// Score turns the provider's signal into Voca's numbers.
func (e *Engine) Score(out domain.AssessmentOutput) domain.Scores {
	accuracy := clamp(out.Accuracy)
	fluency := clamp(out.Fluency)
	completeness := clamp(out.Completeness)

	total := e.weights.Accuracy + e.weights.Fluency + e.weights.Completeness
	if total <= 0 {
		// A misconfigured weight set must not produce a silent zero for every learner.
		return domain.Scores{
			Accuracy: accuracy, Fluency: fluency, Completeness: completeness,
			Overall: accuracy,
		}
	}

	overall := (accuracy*e.weights.Accuracy +
		fluency*e.weights.Fluency +
		completeness*e.weights.Completeness) / total

	return domain.Scores{
		Accuracy:     accuracy,
		Fluency:      fluency,
		Completeness: completeness,
		Overall:      clamp(round1(overall)),
	}
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
