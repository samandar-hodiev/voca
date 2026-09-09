// Shared API envelope types.
//
//   success: { data: T, meta?: { request_id?: string } }
//   error:   { error: { code, message, details?, request_id? } }
//
// Mirrors the backend contract in ARCHITECTURE.md 11.1 and 19.1. The admin switches on the
// error CODE, never on the message text.
