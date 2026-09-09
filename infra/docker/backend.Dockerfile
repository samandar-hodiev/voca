# Backend container image — ARCHITECTURE.md §24
#
# Intended shape: multi-stage build.
#   Stage 1 (builder): golang base, download modules, build a statically linked binary
#     for linux/amd64 with CGO disabled.
#   Stage 2 (runtime): minimal base (distroless or alpine), copy only the binary and
#     migrations, run as non-root, EXPOSE the configured port, ENTRYPOINT the binary.
#
# Requirements:
#   - no secrets baked in; all configuration arrives as environment variables (§25.2)
#   - handles SIGTERM for graceful shutdown so rolling deploys drain cleanly (§24.4)
#   - the same image serves cmd/api and, from Stage 3, cmd/worker via a different
#     entrypoint (§21.3)
