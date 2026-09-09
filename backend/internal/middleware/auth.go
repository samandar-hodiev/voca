// middleware: RequireAuth.
//
// Validates the Bearer access token and places the user ID into context.Context.
//
// Authentication ONLY. Resource ownership is checked in the service layer and is never
// inferred from the URL — a request for someone else's attempt returns 404, not 403, so IDs
// cannot be probed (ARCHITECTURE.md 8.5).
//
// Access token claims are minimal: sub, iat, exp, jti, token_version. Entitlement is
// DELIBERATELY NOT a claim (see entitlement.go).

package middleware
