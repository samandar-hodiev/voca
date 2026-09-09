# Voca — root task entry point.
#
# Intended targets (commands filled in during implementation, ARCHITECTURE.md §26):
#
#   make dev              start the local stack (postgres + api) via infra/compose
#   make down             stop the local stack
#   make migrate          apply database migrations
#   make migrate-down     roll back the last migration
#   make seed             load content seed data
#   make test             run backend and mobile test suites
#   make lint             run golangci-lint and flutter analyze
#   make fmt              run gofmt and dart format
#   make generate         run sqlc generate and the OpenAPI Dart client generator
#   make openapi-validate validate docs/api/openapi.yaml
#
# Delegates to backend/Makefile and mobile tooling rather than duplicating commands.
