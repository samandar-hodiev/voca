// pkg/jwt: generic sign and verify helpers.
//
// Knows nothing about Voca users or entitlement — auth/verifier.go owns that. MVP signs
// HS256; the RS256 move is contained because the mobile client never inspects the signature.
//
// See ARCHITECTURE.md 8.2.

package jwt
