# ADR-007: RevenueCat for subscription management

- **Status:** Proposed
- **Date:** 2026-09-09
- **Related:** [ADR-006](ADR-006-provider-abstraction.md)

## Context

Digital subscriptions on mobile must go through Apple's In-App Purchase and Google Play Billing.
Doing that correctly means server-side receipt validation for two stores, two different subscription
lifecycle models, trials, introductory offers, upgrades and proration, grace periods, billing
retries, refunds, family sharing, and restore-purchases flows, each with its own edge cases and its
own webhook formats. All of it is undifferentiated work, and getting it wrong means either giving
away premium access or wrongly denying a paying customer.

## Decision

Use **RevenueCat** as the subscription infrastructure: its SDK in the Flutter app for purchase and
restore flows, and its webhooks plus server API on the backend, accessed through our own
`PaymentProvider` interface. The backend remains the **only** authority on entitlement.

## Alternatives considered

| Alternative | Why not |
|-------------|---------|
| **Direct StoreKit 2 + Google Play Billing integration** | Full control and no vendor fee, but it is weeks of work plus ongoing maintenance against two evolving APIs, in the area where bugs cost real money and real trust |
| **Adapty or Qonversion** | Comparable products; RevenueCat chosen for maturity, documentation quality, Flutter SDK support, and webhook reliability. The `PaymentProvider` port makes this a swappable decision |
| **Stripe** | Cannot be used for in-app digital subscriptions on iOS or Android under store rules; relevant only for a future web tier |
| **Backend-only receipt validation, no vendor** | Same objections as direct integration, minus the client-side conveniences |

## Rationale

RevenueCat normalizes both stores into one entitlement model and one webhook stream, removing the
highest-risk, lowest-differentiation code in the product. What we keep for ourselves is the part
that matters: our own `Entitlement` concept, our own `subscriptions` state table, our own
append-only `subscription_events` audit log, and our own enforcement.

Critically, this is **not** a decision to trust the client. The app's local entitlement is a UI
hint; every gated action is authorized server-side against state derived from verified webhooks,
with a `/sync` path to self-heal if a webhook is delayed.

## Consequences

**Positive:** store edge cases handled by a specialist; one webhook format; restore purchases works
across platforms; subscription analytics available immediately; far less code in the riskiest area.

**Negative:** a revenue-share fee above a free tier; a dependency in the payment path; entitlement
data lives partly in a third party; webhook delivery must be treated as unreliable.

**Mitigations:** raw webhook payloads stored in `subscription_events` for audit and replay; webhook
processing is idempotent via unique provider event IDs; an expiry sweep plus a reconciliation job
heal missed events; and `PaymentProvider` keeps a future direct-integration path open at adapter
scope.
