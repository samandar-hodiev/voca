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
