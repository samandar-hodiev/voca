// integrations/payment/revenuecat: implements subscription.PaymentProvider.
//
// Selected by PAYMENT_PROVIDER=revenuecat.
//
// RevenueCat handles receipt validation, renewals, grace periods, refunds, proration and
// family sharing across both stores — undifferentiated work where bugs cost real money.
// What stays ours: the Entitlement concept, the subscriptions state table, the
// subscription_events audit log, and all enforcement (ARCHITECTURE.md 9.2, ADR-007).

package revenuecat
