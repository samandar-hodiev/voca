// analytics: server-side event emission.
//
// The backend emits only MONEY AND TRUTH events — assessment_completed, trial_started,
// subscription_started, subscription_renewed, subscription_cancelled, usage_limit_reached.
// UI and funnel events come from the app, because only the client knows they happened, and
// revenue reporting must come from verified webhook state rather than a client claim.
//
// FIRE AND FORGET with a timeout. Never inside a database transaction. Never able to fail a
// user request: an analytics outage must not become a product outage.
//
// Never send raw audio, email addresses, tokens, or free-text user input.
//
// See ARCHITECTURE.md 16.2, 16.5.

package analytics
