// subscription: provider webhook processing.
//
// Verified by shared secret or signature BEFORE parsing — reject anything unverified.
//
// Then, in order:
//   1. append the raw payload to subscription_events (append-only audit log; the one place
//      we deliberately store a raw vendor body, for billing disputes and replay)
//   2. map the vendor event to our own status machine
//   3. upsert current state in subscriptions
//   4. emit a server-side analytics event (trusted, unlike client-reported purchases)
//
// MUST BE IDEMPOTENT: events arrive twice and out of order. Each event carries a provider
// event ID with a unique constraint, and transitions are applied by event timestamp.
//
// Our status model, independent of any store: trialing, active, grace_period, cancelled,
// expired, refunded.
//
// See ARCHITECTURE.md 9.5, 10.6.

package subscription
