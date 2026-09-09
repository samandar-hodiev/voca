// integrations/payment/mock: fake PaymentProvider for tests and local development.
//
// Must be able to produce: free user, active premium, trialing, expired, cancelled but
// still entitled, refunded, and grace period — so entitlement and quota logic can be tested
// exhaustively without touching a store.
//
// These are among the highest-value backend tests (ARCHITECTURE.md 22.1).

package mock
