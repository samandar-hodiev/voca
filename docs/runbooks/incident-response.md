# Incident response runbook. Written BEFORE launch, not after the first incident.
#
# To fill in during implementation step 14 (ARCHITECTURE.md 37):
#   - severity definitions and who is called
#   - dashboards and alert thresholds: error rate, p95 latency, provider failure rate,
#     database connection saturation
#   - how to find a user's request from the X-Request-ID in their screenshot
#   - how to roll back: redeploy the previous commit-SHA image tag
#   - how to put the API into maintenance mode (503 SERVICE_UNAVAILABLE)
#   - how to disable a broken feature without a release, via GET /api/v1/config flags
#   - communication template for affected users
