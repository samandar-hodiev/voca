// subscription: PaymentProvider — the port for subscription state.
//
//   type PaymentProvider interface {
//       Name() string
//       GetCustomerEntitlement(ctx, appUserID) (Entitlement, error)
//       ParseWebhook(ctx, headers, body) (WebhookEvent, error)
//   }
//
// Entitlement and WebhookEvent are OUR types. Apple, Google, and RevenueCat vocabulary
// stops at the adapter boundary, which is what keeps a future move to direct StoreKit or
// Play Billing — or a web tier — from touching business logic.
//
// See ARCHITECTURE.md 9.6, ADR-007.

package subscription
