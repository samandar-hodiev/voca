// jobs: subscription expiry sweep. Runs hourly.
//
// Downgrades entitlements past current_period_end when no webhook arrived. Webhook delivery
// must be treated as unreliable; this plus the /subscriptions/sync path is how missed events
// heal.
//
// Stage 2+ adds a full reconciliation job that re-syncs active subscribers from the provider
// (ARCHITECTURE.md 9.5, 21.3).

package jobs
