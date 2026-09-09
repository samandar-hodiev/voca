# ADR-006: All third-party providers sit behind ports we own

- **Status:** Proposed
- **Date:** 2026-09-09
- **Related:** [ADR-005](ADR-005-azure-speech.md), [ADR-007](ADR-007-revenuecat.md), [ADR-010](ADR-010-redis-optional.md)

## Context

Voca depends on external services for its most important capability (speech assessment), its
revenue (app store billing), its measurement (analytics), and its retention loop (push). Each of
these vendors may change pricing, change API shape, degrade, or need replacing. If vendor types
spread into services, handlers, and UI code, every one of those events becomes a refactor across the
codebase, and testing requires either live calls or elaborate HTTP stubbing.

## Decision

Every external dependency is accessed through an **interface defined by the consuming module**, with
the vendor implementation isolated in `internal/integrations/<capability>/<vendor>/`. Vendor response
types are unexported. Each capability ships a mock implementation alongside the real one.

Ports: `SpeechProvider`, `PaymentProvider`, `AnalyticsProvider`, `NotificationProvider`, `CacheStore`,
`AudioStore`. The mobile app mirrors this with `AnalyticsService` and its audio interfaces.

The provider is selected at startup by configuration (`SPEECH_PROVIDER=azure|google|mock`).

## Alternatives considered

| Alternative | Why not |
|-------------|---------|
| **Call vendor SDKs directly from services** | Fastest initially, then every vendor change touches business logic, tests need network or heavy stubbing, and vendor vocabulary silently becomes our domain vocabulary |
| **A single generic "integration" facade for everything** | One interface serving unrelated capabilities becomes a grab bag that changes for unrelated reasons |
| **Abstract only speech, use others directly** | Speech is the biggest risk, but subscription vocabulary leaking into domain logic is the one most likely to cause correctness bugs, and analytics is the one most likely to be swapped |

## Rationale

The interface belongs to the consumer, not the vendor: it describes what the product needs, phrased
in our domain's language. That single inversion is what makes provider replacement, offline testing,
and cost-free CI possible at once. Go's package visibility enforces it — with Azure's response
structs unexported, no other package *can* reference an Azure field, so the coupling cannot leak by
accident.

The mapping step deserves emphasis: vendor payloads are translated explicitly, field by field, into
our domain models, with golden tests over recorded payloads. Nothing raw is stored, returned to the
app, or passed to business logic.

## Consequences

**Positive:** vendors are replaceable at adapter scope; the whole system is testable without network
access or spend; CI is deterministic and free; a beginner can read a service and understand it
without knowing any vendor SDK; running two providers in parallel for comparison is a decorator.

**Negative:** one extra layer to write and keep in sync; some vendor-specific capability is
deliberately not exposed; mapping code must be maintained as vendor payloads evolve.

**Guard against over-abstraction:** ports exist only for **external systems that could be replaced
or must be mocked**. Internal concepts do not get speculative interfaces, in line with the principle
of avoiding unnecessary abstractions everywhere.
