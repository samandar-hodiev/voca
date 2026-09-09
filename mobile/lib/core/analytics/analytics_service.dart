// core/analytics: the AnalyticsService port.
//
//   track(AnalyticsEvent), identify(userId, traits), screen(name, properties), reset()
//
// Feature code NEVER imports Firebase or PostHog. Swapping providers is a one-line change in
// the composition root (ARCHITECTURE.md 16.1, ADR-006).
