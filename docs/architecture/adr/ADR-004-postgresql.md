# ADR-004: PostgreSQL as the only datastore

- **Status:** Proposed
- **Date:** 2026-09-09
- **Related:** [ADR-010](ADR-010-redis-optional.md)

## Context

Voca's data is overwhelmingly relational: users own sessions, sessions contain items, items have
attempts, attempts break down into phoneme results, subscriptions belong to users. Integrity matters
because entitlement and billing depend on it. But two parts of the model are document-shaped
(word-level result breakdowns, raw webhook payloads) and one is array-shaped and queried by
membership (`words.target_phonemes`).

## Decision

Use **PostgreSQL** as the single datastore for all persistent application data, using JSONB where
document storage genuinely fits and array columns with GIN indexes for phoneme membership queries.

## Alternatives considered

| Alternative | Why not |
|-------------|---------|
| **MongoDB** | Attractive for the nested assessment payload, but our core integrity needs (entitlement, unique identity, foreign keys, transactional progress updates) are exactly what relational constraints give us for free. Weak-sound analysis is aggregate-heavy relational querying |
| **MySQL** | Perfectly capable, but weaker JSONB, no array types with GIN indexing, and a less rich extension ecosystem for the analytical queries we anticipate |
| **PostgreSQL + a separate document store** | Two systems to operate, back up, and keep consistent, to solve a problem JSONB already solves |
| **SQLite** | Fine for a prototype, wrong for a multi-instance service with concurrent writes |

## Rationale

Postgres covers every access pattern in this product without a second system: strong constraints and
transactions for correctness, JSONB where a document is genuinely the right shape, arrays plus GIN
for "find words containing this phoneme", window functions for progress trends, and mature managed
hosting with point-in-time recovery everywhere we might deploy.

Crucially, choosing one datastore keeps the operational surface small, which is the same instinct
behind ADR-003 and ADR-010.

## Consequences

**Positive:** referential integrity enforced by the database; one system to back up, monitor, and
restore; expressive querying for analytics; excellent managed options; well understood by most
developers.

**Negative:** schema changes require migrations and discipline; very high write volume eventually
needs partitioning, replicas, and connection pooling; JSONB fields are not constrained by the
database, so their shape must be enforced in code and tests.

**Mitigation:** section 33 states when partitioning, replicas, and PgBouncer are introduced, and
JSONB shapes are covered by the mapper and golden tests in section 22.
