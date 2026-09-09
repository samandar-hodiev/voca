# ADR-012: One repository holding mobile, admin and backend

- **Status:** Proposed
- **Date:** 2026-09-09
- **Related:** [ADR-008](ADR-008-rest-api.md), [ADR-014](ADR-014-admin-uses-backend-api-only.md)

## Context

Voca is three applications: a Flutter mobile app, a Next.js admin dashboard, and a Go
backend. They are built by one small team and are bound together by one API contract. The
question is whether they live in one repository or three.

## Decision

One repository, with `mobile/`, `admin/` and `backend/` as sibling top-level directories,
plus shared `docs/` and `infra/`. Each application keeps its own toolchain, dependencies,
tests and CI workflow. CI workflows are path-filtered so a mobile change does not run the
backend suite.

## Alternatives considered

| Alternative | Why not |
|-------------|---------|
| **Three repositories** | The API contract, its server and its two consumers change together. Splitting them means a breaking change lands in three pull requests across three repositories, and the window where they disagree is a window where production is broken. Cross-repository versioning is real work that buys nothing at this team size |
| **Two repositories: backend plus a clients repo** | Half the coordination cost with none of the isolation benefit |
| **Monorepo with a shared build tool (Nx, Turborepo, Bazel)** | Solves cross-language task orchestration and caching, problems that appear with many packages and long builds. We have three independent toolchains that do not share code. The tool would be more machinery than the problem justifies |

## Rationale

The decisive argument is the API contract. `docs/api/openapi.yaml` is the single source of
truth for both clients; when it changes, the server and both consumers must change with it.
In one repository that is one commit, one review, and one CI run that can regenerate both
clients and fail the build if either drifts. That protection is the main thing this
architecture relies on to prevent silent client-server divergence (sections 22.3, 38.6).

The usual objection to monorepos is coupled release cycles. It does not apply here: each
application deploys independently, mobile through the stores, admin as a static bundle,
backend as a container. Sharing a repository does not force sharing a release.

Note that this is a monorepo in the "one repository" sense only. There is deliberately **no
shared code package** between mobile and admin (section 31.4), and none is planned.

## Consequences

**Positive:** contract changes are atomic and reviewable in one place; one issue tracker and
one history for the whole product; a new developer clones once; documentation sits beside the
code it describes.

**Negative:** the repository grows large; a naive CI configuration would run everything on
every change; access control is all-or-nothing, so a future contractor cannot be given the
admin without the backend.

**Mitigations:** path filters on every workflow, and the boundaries in section 31.4 enforced
in review. If restricted access ever becomes a real requirement, extracting `admin/` is a
contained operation precisely because it shares no code.
