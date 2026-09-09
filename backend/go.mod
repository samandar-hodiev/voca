# PLACEHOLDER — generate with `go mod init` at implementation step 2 (ARCHITECTURE.md 37).
#
# Proposed module path (CONFIRM BEFORE FREEZE — the GitHub remote is
# github.com/samandar-hodiev/voca, so this should most likely be
# github.com/samandar-hodiev/voca/backend):
#
#   module github.com/samandar-hodiev/voca/backend
#   go 1.23
#
# Planned direct dependencies (ARCHITECTURE.md 5.6):
#   github.com/gin-gonic/gin              HTTP framework
#   github.com/jackc/pgx/v5               PostgreSQL driver + pool
#   github.com/golang-migrate/migrate/v4  migrations
#   github.com/go-playground/validator/v10 request validation
#   github.com/golang-jwt/jwt/v5          access tokens
#   github.com/google/uuid                identifiers
#   github.com/robfig/cron/v3             in-process scheduler
#   github.com/stretchr/testify           test assertions
#   github.com/testcontainers/testcontainers-go  repository tests
#
# Deliberately ABSENT at MVP: any Redis client, any queue library, any ORM.
