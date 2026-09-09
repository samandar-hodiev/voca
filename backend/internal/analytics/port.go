// analytics: AnalyticsProvider — the port for server-side event tracking.
//
//   type AnalyticsProvider interface {
//       Track(ctx, Event) error
//       Identify(ctx, userID, traits) error
//   }
//
// Implementations: posthog, firebase, noop. Selected by ANALYTICS_PROVIDER.
//
// See ARCHITECTURE.md 16.1, ADR-006.

package analytics
