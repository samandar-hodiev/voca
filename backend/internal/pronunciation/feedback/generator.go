// pronunciation/feedback: turns PronunciationError values into learner-facing Feedback.
//
// Produces MESSAGE KEYS AND PARAMETERS, never finished sentences. The Uzbek text lives in
// the app's ARB files, which is what makes a second interface language a translation task
// rather than a backend change.
//
// Each Feedback carries: related word, related phoneme, message key, articulation tip key
// (tongue, lips, airflow), example words, and a priority for ordering on screen.
//
// Feedback is PERSISTED rather than regenerated, so a learner's history does not change
// retroactively when these rules improve.
//
// See ARCHITECTURE.md 6.3, 19.1.

package feedback
