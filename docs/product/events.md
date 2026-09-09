# Analytics event catalogue — the shared contract between the app, the backend, and the
# analytics provider.
#
# Full definitions: ARCHITECTURE.md 16.3.
#
# Keep this file, mobile/lib/core/analytics/events.dart, and
# backend/internal/analytics/events.go in step. When they drift, funnels break silently and
# the damage is only visible weeks later in a report nobody can reconstruct.
#
# Split of responsibility (ARCHITECTURE.md 16.2):
#   CLIENT emits UI and funnel events — only the client knows they happened.
#   BACKEND emits money and truth events — a client can be tampered with, and revenue
#   reporting must come from verified webhook state.
#
# Every event carries: user_id (pseudonymous UUID, never an email), platform, app_version,
# ui_language, entitlement_tier, session_id.
#
# Never attach: raw audio, email addresses, tokens, or free-text user input.
