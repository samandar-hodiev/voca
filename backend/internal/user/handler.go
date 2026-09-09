// user: HTTP handlers. THIN LAYER — no business logic.
//
// Responsibility: bind and validate the request DTO, read the authenticated user from
// context, call exactly ONE service method, map the domain result or error to HTTP.
//
// MUST NOT contain: SQL, provider calls, or business branching such as "if user is premium".
//
// See ARCHITECTURE.md 8.4, 5.3 (handler rules), 19 (error mapping), 31.2 (dependency rules).

package user
