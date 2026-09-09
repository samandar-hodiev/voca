# ADR-002: Go with Gin for the backend

- **Status:** Proposed
- **Date:** 2026-09-09
- **Related:** [ADR-003](ADR-003-modular-monolith.md), [ADR-008](ADR-008-rest-api.md)

## Context

The backend's dominant workload is I/O-bound request handling: accept an audio upload, call an
external assessment API, map and score the response, write a few rows, return JSON. It must be cheap
to run on a single small instance at MVP, trivially deployable, and readable by developers who may be
new to the language. It also has to hold a clean modular structure that can later be split apart.

## Decision

Build the backend in **Go**, using **Gin** as the HTTP framework, **pgx** as the PostgreSQL driver,
and **sqlc** to generate type-safe Go from hand-written SQL.

## Alternatives considered

| Alternative | Why not |
|-------------|---------|
| **Node.js / NestJS** | Fast to write and familiar to many, but higher memory per instance, a heavier dependency tree to audit, and runtime type-safety gaps in exactly the mapping code (provider payload to domain) where we most want compile-time guarantees |
| **Python / FastAPI** | Excellent developer experience and the natural choice if we were running our own ML models. We are not: assessment is a managed API call. We would pay Python's concurrency and deployment weight for a benefit we do not use |
| **Java / Kotlin + Spring** | Strong ecosystem, but heavyweight startup, memory footprint, and configuration surface for a service of this size |
| **Rust** | Best performance and safety, at a cost in development speed and hiring for a product whose bottleneck is a third-party API, not our CPU |

## Rationale

Go compiles to a single static binary that starts in milliseconds and runs comfortably in a small
container, which directly shapes the deployment story in section 24. Its concurrency model fits
"wait on an external API" perfectly. Static typing plus explicit interfaces make the provider
abstractions in ADR-006 natural rather than ceremonial, and the compiler enforces the `internal/`
package boundary that protects module structure. The language is small enough that a developer new
to it becomes productive quickly, which matters because this document is meant to be buildable by a
beginner Go developer.

sqlc is chosen over an ORM deliberately: the developer writes real SQL, sees the query plan, and
gets generated Go structs with compile-time safety. There is no hidden query generation to debug
under load.

## Consequences

**Positive:** small, fast, cheap-to-run service; excellent standard library including structured
logging; straightforward Docker images; interfaces make mocking trivial for testing.

**Negative:** more verbose than Python or TypeScript; explicit error handling on every call;
generics are newer and less idiomatic; fewer batteries included than Spring or NestJS, so we
assemble middleware, validation, and configuration ourselves.

**Mitigation:** the assembly work is one-time, done in `internal/server` and `internal/middleware`,
and section 28 specifies exactly where each piece lives.
