# ADR-010: Redis designed for, but not deployed at MVP

- **Status:** Proposed
- **Date:** 2026-09-09
- **Related:** [ADR-004](ADR-004-postgresql.md), [ADR-003](ADR-003-modular-monolith.md)

## Context

Several features in the roadmap are natural Redis workloads: distributed rate limiting, daily usage
counters, content caching, short-TTL entitlement caching, a background job queue, and leaderboard
sorted sets. But at MVP there is one API instance and low traffic, where PostgreSQL handles all of
this comfortably. Deploying Redis now would add a managed service, a failure mode, a cache-
invalidation problem, and a cost, in exchange for performance nobody would notice.

The risk of *not* planning for it is worse: retrofitting a cache layer into code that assumes direct
database access tends to become an invasive change.

## Decision

**Do not deploy Redis for MVP.** Define a `CacheStore` interface now and ship a real **in-process
implementation** (TTL map, bounded size) behind `CACHE_DRIVER=memory`. Adding Redis later is a
`redis` implementation of the same interface plus a configuration change.

Rate limiting and usage counters are written against this interface from day one.

## Alternatives considered

| Alternative | Why not |
|-------------|---------|
| **Deploy Redis from day one** | An extra component to run, monitor, secure, and pay for, plus cache-invalidation bugs, to solve a load problem that does not exist yet |
| **No cache abstraction at all** | Retrofitting caching later means touching every call site it should wrap, at exactly the moment the system is under load |
| **Cache inside PostgreSQL (unlogged tables)** | Possible, but adds write load to the component we most want to protect |
| **In-process cache only, forever** | Breaks correctness the moment a second instance runs: rate limits and quota counters would be enforced per instance |

## Rationale

The in-memory implementation is a real implementation, not a stub. Caching code paths exist, run,
and are tested from day one, so introducing Redis is proven-correct by tests that already pass
against the memory driver. This is the general pattern used throughout this architecture: build the
seam, defer the component.

The one behavioural difference between drivers — sharing state across instances — is exactly the
trigger for adoption. Redis is introduced at Stage 2, when a second API instance is added, because
at that point in-memory counters stop being correct rather than merely slower.

## Consequences

**Positive:** fewer moving parts, lower cost, and less operational surface at MVP; no premature
cache-invalidation complexity; adoption later is a configuration change; the leaderboard and job
queue paths in the roadmap already have their home.

**Negative:** the memory driver is per-instance, so single-instance deployment is required until
Redis is adopted; some optimizations wait; two implementations must be kept behaviourally
equivalent.

**Guardrails:** caches always carry a TTL, PostgreSQL is always the source of truth, and nothing
affecting money or entitlement is cached for more than about a minute.
