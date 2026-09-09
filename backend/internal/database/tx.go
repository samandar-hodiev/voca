// database: transaction helper.
//
// Provides the pattern services use to run several repository calls in ONE transaction —
// for example persisting an attempt, its phoneme results, its feedback, and the
// daily_progress upsert together.
//
// Transaction boundaries belong to the SERVICE layer, not to repositories and not to
// handlers (ARCHITECTURE.md 5.3, 6.1 step 8).

package database
