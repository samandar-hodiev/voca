// cache: Redis implementation. NOT USED AT MVP — created when CACHE_DRIVER=redis at Stage 2.
//
// Planned uses, in the order they will be needed (ARCHITECTURE.md 20.3):
//   rate limit counters -> daily usage quota counters -> word and category content cache ->
//   entitlement cache (60s TTL) -> refresh-token revocation list -> job queue backing store
//   -> leaderboard sorted sets when gamification ships.
//
// Must remain behaviourally equivalent to memory.go; the same tests run against both.

package cache
