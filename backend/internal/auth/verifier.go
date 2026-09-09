// auth: identity token verification.
//
// Defines TokenVerifier (the port) and its Apple and Google implementations. Verifies the
// identity token the app obtained natively: signature against the provider JWKS, issuer,
// audience, expiry, and nonce.
//
// Also holds the JWT signing/verification seam. MVP uses HS256; moving to RS256 when a
// second service must verify tokens independently is a change contained to this file
// because the mobile client never inspects the signature.
//
// Never log a token, a secret, or a JWKS private key — ARCHITECTURE.md 18.4.
//
// See ARCHITECTURE.md 8.1, 8.2.

package auth
