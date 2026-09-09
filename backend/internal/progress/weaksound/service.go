// progress/weaksound: identifies a learner's recurring pronunciation weaknesses.
//
// Aggregates phoneme_results over a rolling window (last 30 days or last 200 observations)
// per (user_id, phoneme), using the (user_id, phoneme, created_at DESC) index.
//
// MVP thresholds, ALL configuration rather than constants because they will be tuned
// against real data:
//   - minimum 5 occurrences before saying anything (noise is not a diagnosis)
//   - average score below 60
//   - error rate at or above 30 percent
//   - severity: severe under 40, moderate 40-59, minor 60-69 with a high error rate
//   - recent occurrences weighted higher so improvement shows quickly
//
// Reads phoneme data through the pronunciation module's repository interface, never by
// touching its tables directly, so this can later move to a read replica, a materialized
// view, or its own service.
//
// Scale seam: when live aggregation gets expensive, add a user_phoneme_stats rollup table
// maintained by a job. The API contract does not change.
//
// See ARCHITECTURE.md 15.

package weaksound
