# ADR-009: URL path versioning with an additive-only v1

- **Status:** Proposed
- **Date:** 2026-09-09
- **Related:** [ADR-008](ADR-008-rest-api.md)

## Context

Mobile clients cannot be force-updated. After a store release, some users stay on an old app version
for months, and store review makes hotfixes slow. Any breaking API change therefore breaks real,
paying users. The API must be versioned from the very first release, because retrofitting versioning
onto a deployed unversioned API is itself a breaking change.

## Decision

Version in the **URL path**: `/api/v1/...`. Within a released version the contract is
**additive-only**:

- Fields may be added; never removed, renamed, or retyped.
- Enum values may be added; clients must ignore unknown values.
- New optional request parameters are allowed; new required ones are not.
- Breaking changes create `/api/v2`, and `v1` remains until analytics show old app versions have
  drained.

The router mounts modules under a version group, so `v2` is a second group reusing the same
services.

## Alternatives considered

| Alternative | Why not |
|-------------|---------|
| **Header versioning** (`Accept: application/vnd.voca.v2+json`) | Purer by REST doctrine, but invisible in logs, dashboards, and curl commands, and easy to omit by mistake. Version should be obvious at a glance during an incident |
| **Query parameter versioning** (`?v=2`) | Easy to forget, awkward to cache, and mixes routing with filtering |
| **No versioning, evolve in place** | Works only when clients can be updated in lockstep. Mobile clients cannot |
| **Date-based versions** | Powerful for large public APIs with many consumers; unnecessary ceremony for one first-party client |

## Rationale

Path versioning is explicit and self-documenting: the version appears in every log line, metric
label, and bug report, so "which version is that user on?" is answerable instantly. It also makes
routing trivial in Gin and lets both versions run in the same binary during a transition.

The additive-only rule matters more than the versioning scheme itself. Most changes we anticipate
(new practice types, new score fields, new feedback categories) are additive by nature, so `v2`
should be rare. Client-side, the app must therefore tolerate unknown enum values and unexpected
fields rather than failing to parse.

## Consequences

**Positive:** old app versions keep working; version visible everywhere; simple routing; multiple
versions can coexist in one deployment.

**Negative:** URLs carry a version that is duplicated across every route; supporting two versions
temporarily means maintaining two handler sets; discipline is required to keep changes additive.

**Supporting mechanism:** `GET /api/v1/config` returns a minimum supported app version, so we can
prompt or force an upgrade when a version genuinely must be retired.
