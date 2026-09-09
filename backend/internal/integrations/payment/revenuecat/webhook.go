// integrations/payment/revenuecat: webhook parsing and verification.
//
// Verifies REVENUECAT_WEBHOOK_SECRET BEFORE parsing the body, then maps the vendor payload
// to our WebhookEvent type. Vendor vocabulary stops here.
//
// See ARCHITECTURE.md 9.5, 9.6.

package revenuecat
