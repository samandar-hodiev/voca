// middleware: structured request logging (log/slog, JSON).
//
// Every line carries: request_id, method, path, status, duration_ms, user_id when
// authenticated, app_version.
//
// NEVER LOG: passwords, access or refresh tokens, Apple/Google identity tokens, API keys or
// secrets, raw audio or audio contents, email addresses, or full request bodies for auth
// and upload endpoints.
//
// That list is a hard rule, not a guideline — ARCHITECTURE.md 18.4.

package middleware
