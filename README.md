# Voca — English Pronunciation Coach

AI-powered English pronunciation coaching for mobile. First UI language: Uzbek.
First learning language: English (en-US).

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
| `backend/` | Go modular monolith (Gin + PostgreSQL) — ARCHITECTURE.md §5, §28 |
| `docs/architecture/` | The architecture specification and decision records |
| `docs/api/` | OpenAPI contract, the shared source of truth for both sides |
| `docs/database/` | Schema notes and ERD |
| `docs/product/` | Analytics event catalogue and metric definitions |
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

## Rules that hold everywhere

- No secrets in the mobile app. Ever. Azure and RevenueCat keys are backend-only.
- No vendor SDK outside `backend/internal/integrations/`.
- No SQL in HTTP handlers; no business logic in handlers or widgets.
- The backend is the only authority on subscription entitlement.
