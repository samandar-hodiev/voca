// pronunciation/scoring: ScoringEngine — turns a provider signal into Voca scores.
//
// PRINCIPLE: the provider gives us a SIGNAL, not the truth. Azure's numbers come from a
// model we do not control, tuned on speakers who may not resemble Uzbek learners, over
// audio from phone microphones of varying quality. This engine is where scoring POLICY
// lives so that our core metric stays ours.
//
// MVP policy: accuracy, fluency and completeness pass through; overall is a weighted blend
// (0.5 accuracy, 0.3 fluency, 0.2 completeness) clamped to 0-100; confidence is reduced for
// very short audio, clipping, silence, or provider warnings.
//
// Rules that keep this evolvable:
//   - every attempt records scoring_version, so old rows stay interpretable
//   - weights come from configuration, never from constants scattered in code
//   - a future calibrated or hybrid model is a new implementation behind the same call
//
// See ARCHITECTURE.md 6.4.

package scoring
