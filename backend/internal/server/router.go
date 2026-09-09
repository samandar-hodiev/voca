// server: router assembly.
//
// Installs the middleware chain in order, then mounts each module's routes under the
// /api/v1 group:
//
//   request_id -> logger -> recovery -> cors -> rate limit -> auth -> entitlement
//
// Version groups live here. A future /api/v2 is a SECOND GROUP reusing the same services,
// which is what allows both versions to run in one binary while old app versions drain.
//
// See ARCHITECTURE.md 5.2, 11.1, ADR-009.

package server
