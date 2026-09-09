# ADR-014: The admin reaches data only through the backend API

- **Status:** Proposed
- **Date:** 2026-09-09
- **Related:** [ADR-003](ADR-003-modular-monolith.md), [ADR-013](ADR-013-nextjs-for-admin.md)

## Context

The admin dashboard needs to read and write the same data the mobile product uses. Next.js
can run server-side code, so connecting it straight to PostgreSQL is technically easy and
would be faster to build for the first few screens.

## Decision

The admin has **no database access**: no driver, no connection string, no migration runner,
no ORM. Every read and write goes through `/api/v1/admin/*` on the Go backend. The admin
also holds **no business logic** and **no secrets**.

## Alternatives considered

| Alternative | Why not |
|-------------|---------|
| **Direct database access from Next.js server components** | Every rule that protects data would then exist twice: entitlement, moderation state transitions, cascade behaviour, audit logging, validation. Two implementations of a rule diverge, and the divergence is discovered in production. It also gives a browser-facing application a database credential |
| **A separate admin backend service** | A second service to deploy, secure and keep in sync with a schema it does not own, contradicting the modular monolith decision in ADR-003 |
| **Shared query library imported by both** | Would have to be written in Go and TypeScript, or force one language on the other. The API already is that shared layer |

## Rationale

The backend is the single place where business rules live (section 5.3). The instant a
second application can write to the database, that statement stops being true, and every
guarantee built on it becomes conditional.

The cost is real and accepted: some admin screens need an endpoint written before they can
be built, which is slower than issuing a query. That friction is the point. It forces
operational needs to be expressed as a reviewed, tested, audited API rather than as ad-hoc
SQL behind a login page.

A related consequence: the new `internal/admin` module composes existing module services
through their exported interfaces. It does not reach into their repositories or tables, so
the admin cannot become a back door around the module boundaries in section 5.5.

## Consequences

**Positive:** one implementation of every rule; the admin cannot corrupt data in ways the
API forbids; every privileged action passes through middleware that can authorize and audit
it; the admin is a pure client, so it can be rebuilt or replaced without touching data;
no database credential ever reaches a browser-facing deployment.

**Negative:** more endpoints to write; some aggregate screens need a purpose-built endpoint
rather than a join; the admin cannot be built ahead of the API.

**Enforcement:** the admin's dependency manifest contains no database client, and dependency
review rejects one. This is the single most important boundary in section 31.4.
