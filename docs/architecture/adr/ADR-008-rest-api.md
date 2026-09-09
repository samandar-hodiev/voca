# ADR-008: REST over JSON for the client API

- **Status:** Proposed
- **Date:** 2026-09-09
- **Related:** [ADR-009](ADR-009-api-versioning.md), [ADR-002](ADR-002-go-for-backend.md)

## Context

There is exactly one client (the Flutter app), a small number of screens, and one genuinely unusual
request: a multipart audio upload that must be streamed and validated before reaching a paid
external API. The API contract must be readable, debuggable from a terminal, and stable across app
versions we cannot force users to update.

## Decision

Expose a **REST API over JSON** under `/api/v1`, with a standard success envelope
(`{"data": ..., "meta": ...}`) and error envelope (`{"error": {"code", "message", "details"}}`),
documented in OpenAPI and used to generate the Dart client models.

## Alternatives considered

| Alternative | Why not |
|-------------|---------|
| **GraphQL** | Solves over-fetching and client-driven queries — problems a single first-party client with fixed screens does not have. It would add schema, resolver, query-complexity, and caching machinery, and it handles binary upload awkwardly |
| **gRPC** | Efficient and strongly typed, and a reasonable future choice for service-to-service calls after Stage 4 extraction. For a mobile client it complicates debugging, proxying, and inspection, with no meaningful payoff at our payload sizes |
| **No formal contract** | Guarantees app/server drift, which is the most expensive class of mobile bug because the client cannot be hotfixed |

## Rationale

REST is the lowest-friction option for one client and a small team: every request is inspectable
with curl, cacheable where useful (content endpoints use ETags), and trivially supported by Dio and
Gin. Multipart upload is native to HTTP rather than bolted on. And OpenAPI plus generated Dart
models gives us the type-safety benefit that GraphQL and gRPC are usually chosen for, without their
operational weight.

Deliberate design choices inside REST reduce chattiness where it actually matters: `GET /users/me`
returns user, profile, preferences, and entitlement in one call, and a practice session returns its
items with words embedded so the practice screen never issues N+1 requests.

## Consequences

**Positive:** simple to build, document, debug, and test; excellent tooling; easy to add endpoints;
CDN and HTTP caching available; generated client models prevent drift.

**Negative:** occasional over-fetching; multiple round trips for unrelated data; endpoint count
grows with features; response shapes must be curated deliberately rather than composed by the
client.

**Mitigation:** composite endpoints where screens demand them, and OpenAPI validation in CI so the
contract is enforced rather than described.
