// jobs: streak rollover. Runs hourly, timezone-aware.
//
// Resets current_streak for users whose local day ended without a successful attempt.
// Calls progress.Service.RolloverStreaks — no logic here.
//
// Day boundaries use user_preferences.timezone, never server time. A FAILED provider call
// must never break a streak: we do not punish users for our outages.
//
// See ARCHITECTURE.md 14.3, 21.1.

package jobs
