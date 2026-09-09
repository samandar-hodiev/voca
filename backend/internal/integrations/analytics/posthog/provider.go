// integrations/analytics/posthog: implements analytics.AnalyticsProvider.
//
// Fire-and-forget with a timeout; never blocks or fails a user request.
//
// Never transmits raw audio, email addresses, tokens, or free-text user input
// (ARCHITECTURE.md 16.5).

package posthog
