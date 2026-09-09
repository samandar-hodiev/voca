// middleware: RequirePremium.
//
// Looks up current entitlement through subscription.Service for endpoints that are wholly
// premium.
//
// WHY THIS IS NOT A JWT CLAIM: a 15-minute-old claim would let a cancelled or refunded
// subscription keep working, and would make a fresh purchase feel broken until the token
// refreshed. The lookup is a cheap indexed read, and Stage 2 adds a 60-second cache.
//
// The mobile app's local entitlement is a UI hint only. This is the authority.
//
// See ARCHITECTURE.md 9.4.

package middleware
