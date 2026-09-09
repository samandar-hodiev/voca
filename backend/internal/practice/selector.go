// practice: PracticeSelector — chooses which content a session contains.
//
//   PracticeSelector.Select(ctx, userID, criteria) -> []Word
//
// MVP strategy: filter by learning language, accent, active status, and the user's
// difficulty; exclude words recently practised well; prefer higher frequency_rank; shuffle
// deterministically per day so daily practice is stable if the app is reopened.
//
// This interface is the seam for the whole personalization roadmap. Adaptive difficulty,
// spaced repetition, and weak-sound targeting are NEW IMPLEMENTATIONS of this interface,
// selected by configuration — not edits to sessions, items, attempts, or the app.
//
// See ARCHITECTURE.md 13.2, 15.4, 34.

package practice
