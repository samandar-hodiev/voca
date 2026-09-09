// progress/recommendation: builds LearningRecommendation from weak-sound data.
//
// Given a weak phoneme, finds active words at the user's level whose target_phonemes array
// contains it, ordered by frequency_rank. One GIN-indexed query — which is exactly why
// words.target_phonemes exists in the MVP schema even though this feature ships later.
//
// LearningRecommendation is COMPUTED, not stored: we do not create a table for data we can
// derive until query cost says otherwise.
//
// See ARCHITECTURE.md 6.3, 15.4, 10.9.

package recommendation
