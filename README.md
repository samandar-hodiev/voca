# Voca — English Pronunciation Coach

AI-powered English pronunciation coaching. First UI language: Uzbek. First learning
language: English (en-US).

The product is three applications sharing one repository:

| Application | Stack | Audience |
|-------------|-------|----------|
| `mobile/` | Flutter, iOS and Android | learners |
| `admin/` | Next.js, TypeScript, Tailwind | owner and admins |
| `backend/` | Go, Gin, PostgreSQL | serves both, owns all business logic |

## Current state

**Architecture is designed. Implementation has started at the edges only.**

The repository holds the architecture specification plus a structural skeleton in which
most source files are still placeholders carrying only a comment about what belongs in
them.

What is actually implemented and running:

- the HTTP server, configuration, middleware and the standard response envelope
- `GET /health`
- `POST /api/v1/webhooks/github` — GitHub push events, HMAC-SHA256 verified, forwarded
  to Telegram (`internal/devhook` + `internal/integrations/telegram`)

Everything in the learning product itself (auth, content, practice, pronunciation,
progress, subscriptions) is still a placeholder.

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
| `admin/` | Next.js admin dashboard — ARCHITECTURE.md §38. Scaffold only, not initialized |
| `backend/` | Go modular monolith (Gin + PostgreSQL) — ARCHITECTURE.md §5, §28 |
| `docs/architecture/` | The architecture specification and decision records |
| `docs/api/` | OpenAPI contract, the shared source of truth for both sides |
| `docs/database/` | Schema notes and ERD |
| `docs/product/` | Analytics event catalogue and metric definitions |
| `docs/design/` | The design language shared by both clients: tokens and principles, never code |
| `docs/ux/` | User journeys and flows, agreed before any screen is built |
| `docs/runbooks/` | Operational procedures |
| `infra/` | Docker, compose files, deployment config |
| `scripts/` | Developer convenience commands |
| `.github/workflows/` | CI/CD pipelines |

## Running the backend locally

```
cd backend
cp .env.example .env      # then fill in GITHUB_WEBHOOK_SECRET and the Telegram values
go mod tidy
go test ./...
go run ./cmd/api
```

The server listens on `PORT`, defaulting to **8082**.

```
curl http://localhost:8082/health
```

Without `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` the service still runs and logs the
notification it would have sent, so no vendor credentials are needed for development.
Without `GITHUB_WEBHOOK_SECRET` every webhook request is rejected, which is the safe
default.

## Start here

1. `docs/architecture/ARCHITECTURE.md` — the full specification (37 sections).
2. `docs/architecture/adr/` — eleven decision records explaining why each major choice was made.
3. Section 37 of the specification — the recommended implementation order.

## Rules that hold everywhere.

- No secrets in either client. Ever. Azure, AI and RevenueCat keys are backend-only.
  Anything prefixed `NEXT_PUBLIC_` is compiled into the browser bundle and is public.
- Neither client touches PostgreSQL. Both go through the REST API.
- No business rule is implemented twice. It lives in a Go service or it does not exist.
- No vendor SDK outside `backend/internal/integrations/`.
- No SQL in HTTP handlers; no business logic in handlers, widgets or React components.
- The backend is the only authority on subscription entitlement and on admin authorization.
  A hidden button is not an access control.
- Mobile and admin share design tokens and an API contract. They never share UI code.
