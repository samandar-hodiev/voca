// jobs: stale session sweep. Runs hourly.
//
// Marks abandoned in_progress practice sessions as abandoned, so completion-rate analytics
// stay honest (ARCHITECTURE.md 13.3, 16.4).

package jobs
