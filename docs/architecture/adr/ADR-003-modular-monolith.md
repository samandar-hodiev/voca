# ADR-003: Modular monolith as the initial backend architecture

- **Status:** Proposed
- **Date:** 2026-09-09
- **Related:** [ADR-011](ADR-011-no-microservices-initially.md), [ADR-004](ADR-004-postgresql.md)

## Context

Voca's backend has clearly separable concerns: identity, content, practice, assessment, progress,
monetization, notifications. That separability tempts a service-per-concern design. But at MVP there
is one small team, no traffic, and no independent scaling need, while the cost of distribution
(network failure modes, distributed transactions, multi-service deploys, cross-service debugging)
would be paid immediately and in full.

The real requirement is not "microservices" but "the ability to become microservices later without a
rewrite".

## Decision

Build a **modular monolith**: one Go binary and one database, internally divided into modules
(`auth`, `user`, `word`, `practice`, `pronunciation`, `progress`, `subscription`, `notification`,
`analytics`), each owning its handlers, service, repository, and domain models, and communicating
only through exported service interfaces.

Four rules make the boundary real:

1. A module calls another module only through its exported service interface, injected at wiring time.
2. A module never imports another module's repository, models, or SQL.
3. A module never reads or writes another module's tables.
4. Shared concerns live in `internal/shared` and `pkg`, never in a business module.

## Alternatives considered

| Alternative | Why not |
|-------------|---------|
| **Microservices from day one** | Solves scaling and team-autonomy problems we do not have, while adding latency, partial-failure handling, distributed tracing needs, and multi-repo deployment to a team that should be shipping product |
| **Unstructured monolith** | Faster in week one, then progressively slower. Without module boundaries the extraction path disappears and every change risks unrelated behaviour |
| **Serverless functions per endpoint** | Cold starts hurt the assessment path, connection management against Postgres becomes awkward, and local development and testing get harder |

## Rationale

A single binary means one deploy, one log stream, one debugger, in-process calls with no network
failure modes, and database transactions that actually span the work they need to span. Meanwhile
the module boundaries are drawn exactly where we would later cut, so extraction is mechanical: the
`pronunciation` module already reaches `subscription` through one interface, and replacing that with
an HTTP client behind the same interface leaves the rest untouched.

## Consequences

**Positive:** fastest path to a working product; simple operations; cheap to run; easy onboarding;
strong transactional consistency; extraction stays possible.

**Negative:** the whole service scales as one unit; a bad deploy affects everything; and module
discipline depends on people, not on process boundaries.

**Mitigation:** `internal/` visibility, `depguard` lint rules, and a review checklist enforce the
boundaries mechanically. Section 33 defines the triggers at which extraction is reconsidered, so the
decision gets revisited on evidence rather than on instinct.
