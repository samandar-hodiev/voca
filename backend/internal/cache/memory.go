// cache: in-process implementation (TTL map, bounded size). The MVP default,
// CACHE_DRIVER=memory.
//
// This is a REAL implementation, not a stub. Its one behavioural difference from Redis —
// state is not shared across instances — is exactly the trigger for adopting Redis: the
// moment a second API instance runs, rate limits and quota counters become INCORRECT rather
// than merely slower.
//
// See ARCHITECTURE.md 20.2, 33 Stage 2.

package cache
