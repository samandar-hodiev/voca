// cache: the CacheStore port.
//
//   type CacheStore interface {
//       Get(ctx, key, dest) (bool, error)
//       Set(ctx, key, val, ttl) error
//       Delete(ctx, keys...) error
//       Increment(ctx, key, ttl) (int64, error)
//   }
//
// REDIS IS NOT DEPLOYED AT MVP (ADR-010). This interface is the seam: caching code paths
// exist, run, and are tested from day one against the memory driver, so introducing Redis
// later is proven correct by tests that already pass.
//
// Rules: every cache entry has a TTL; PostgreSQL is always the source of truth; nothing
// affecting money or entitlement is cached for more than about a minute.
//
// See ARCHITECTURE.md 20.

package cache
