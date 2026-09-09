# ADR-011: No microservices, Kubernetes, or message broker at MVP

- **Status:** Proposed
- **Date:** 2026-09-09
- **Related:** [ADR-003](ADR-003-modular-monolith.md), [ADR-010](ADR-010-redis-optional.md)

## Context

The long-term architecture sketch for Voca shows an API gateway fronting auth, pronunciation, user,
subscription, and notification services. It is a reasonable end state at large scale. The question
this record settles is *when* — and the honest answer is: not at MVP, and probably not for years.

MVP has one team, no users yet, and one workload that matters. Adopting microservices now would mean
service discovery, inter-service authentication, distributed tracing before there is anything to
trace, eventual consistency in flows that are currently a single transaction, multiple deployment
pipelines, and local development that requires several processes to be running before a screen works.

## Decision

For MVP and until the triggers in section 33 are met, Voca runs as **one Go service, one PostgreSQL
database, one container**, deployed on a managed container platform.

Explicitly excluded now:

- Microservices or service-per-domain deployment
- Kubernetes (the platform's built-in orchestration is sufficient)
- Kafka, RabbitMQ, or any message broker
- Service mesh, API gateway, or sidecars
- Separate databases per module

## Alternatives considered

| Alternative | Why not |
|-------------|---------|
| **Microservices now** | Pays the full operational and cognitive cost immediately for benefits (independent scaling, team autonomy, fault isolation) that require scale and headcount we do not have. It is the most common way small teams fail to ship |
| **Kubernetes now** | A powerful platform that becomes a second product to maintain. Managed container platforms give rolling deploys, health checks, and autoscaling with a fraction of the surface |
| **Kafka now** | Justified by high-volume event streams and multiple consumers. We have neither; a database table and an in-process scheduler cover MVP job needs |
| **Splitting only pronunciation out immediately** | The most defensible split, and the first one we would make. Still premature: it adds a network boundary and a deployment before we know the real traffic shape or cost profile |

## Rationale

Every element on the exclusion list solves a problem of scale, team size, or organizational
boundaries. None of those problems exists at MVP, while all of their costs would be immediate. What
we owe the future is not premature distribution but a structure that makes distribution cheap when
it is justified — which is precisely what ADR-003's module boundaries provide.

The extraction path is concrete: `pronunciation` first (highest traffic, heaviest external I/O,
distinct cost profile), then `notification` (queue-shaped and bursty). Because modules already
communicate through exported service interfaces and never touch each other's tables, extraction
means moving a package and replacing an in-process call with an HTTP client behind the same
interface.

## Consequences

**Positive:** a small team ships a product; one deploy, one log stream, one debugger; local
development is `make dev`; transactions stay simple; infrastructure cost is a fraction of the
alternative.

**Negative:** the whole service scales together; a bad deploy affects every feature; a runaway
assessment workload could affect unrelated endpoints; and there is no enforced boundary between
modules beyond package visibility and review discipline.

**Mitigations:** lint-enforced import rules, per-route rate limits, stateless instances so
horizontal scaling is available immediately, and the staged triggers in section 33 that convert
this from a permanent stance into a dated decision to be revisited on evidence.
