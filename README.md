# Voca — English Pronunciation Coach

AI-powered English pronunciation coaching for mobile. First UI language: Uzbek.
First learning language: English (en-US).

## Current state

**Architecture is designed. Implementation has not started.**

This repository currently contains the architecture specification and an empty
structural skeleton. Every source file is a placeholder holding only a comment that
states what belongs in it and which dependency rules apply. There is no logic yet, by
design.

The process is:

```
Design  ->  Review  ->  Freeze  ->  Implement module by module
```

Implementation begins only after the **Architecture Freeze Checklist** at the end of
`docs/architecture/ARCHITECTURE.md` has been reviewed and approved.

## Layout

| Path | Purpose |
|------|---------|
| `mobile/` | Flutter app (feature-based Clean Architecture) — ARCHITECTURE.md §4, §27 |
| `backend/` | Go modular monolith (Gin + PostgreSQL) — ARCHITECTURE.md §5, §28 |
| `docs/architecture/` | The architecture specification and decision records |
| `docs/api/` | OpenAPI contract, the shared source of truth for both sides |
| `docs/database/` | Schema notes and ERD |
| `docs/product/` | Analytics event catalogue and metric definitions |
| `docs/runbooks/` | Operational procedures |
| `infra/` | Docker, compose files, deployment config |
| `scripts/` | Developer convenience commands |
| `.github/workflows/` | CI/CD pipelines |

## Start here

1. `docs/architecture/ARCHITECTURE.md` — the full specification (37 sections).
2. `docs/architecture/adr/` — eleven decision records explaining why each major choice was made.
3. Section 37 of the specification — the recommended implementation order.

## Rules that hold everywhere

- No secrets in the mobile app. Ever. Azure and RevenueCat keys are backend-only.
- No vendor SDK outside `backend/internal/integrations/`.
- No SQL in HTTP handlers; no business logic in handlers or widgets.
- The backend is the only authority on subscription entitlement.
