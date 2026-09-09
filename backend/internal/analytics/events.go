// analytics: the typed server-side event catalogue.
//
// Events are TYPED, not stringly-typed, so an event name or property cannot be misspelled
// in one place and silently break a funnel. Every event carries the common context:
// user_id (pseudonymous UUID, never an email), platform, app_version, ui_language,
// entitlement_tier.
//
// Keep this list in step with mobile/lib/core/analytics/events.dart and with
// docs/product/events.md.
//
// See ARCHITECTURE.md 16.3, 16.4.

package analytics
