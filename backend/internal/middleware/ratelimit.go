// middleware: rate limiting.
//
// Per-IP on auth endpoints, per-user on assessment endpoints, plus a global safety limit.
// Returns 429 RATE_LIMITED with Retry-After.
//
// MVP uses an in-process token bucket through the CacheStore interface. The moment a second
// API instance runs, in-memory counters stop being CORRECT rather than merely slower — that
// is the trigger for adopting Redis (ARCHITECTURE.md 20.3, 33 Stage 2).
//
// Limits come from RATE_LIMIT_* configuration.

package middleware
