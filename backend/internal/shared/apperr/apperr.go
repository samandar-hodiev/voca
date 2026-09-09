// shared/apperr: the single error taxonomy.
//
//   AppError{Code, HTTPStatus, Message, Details, Err}
//
// Services return domain errors; ONE mapping function turns them into HTTP responses. There
// is exactly one place in the codebase where an error becomes a status code.
//
// Categories (ARCHITECTURE.md 19.2): validation 400, payload too large 413, authentication
// 401, authorization 403, not found 404, conflict 409, rate limit and quota 429, provider
// 502/503/504, internal 500.
//
// USAGE_LIMIT_REACHED and PREMIUM_REQUIRED are deliberately DISTINCT codes: one means "come
// back tomorrow or upgrade", the other means "not in your plan". The app shows different
// screens, so the API must not collapse them.
//
// Database and provider errors are WRAPPED, never surfaced: a client must never see a
// constraint name, table name, driver message, vendor error body, or stack trace. Internal
// detail goes to the log with the request ID; the client gets INTERNAL_ERROR and that ID.

package apperr
