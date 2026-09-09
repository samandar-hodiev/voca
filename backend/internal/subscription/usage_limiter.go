// subscription: UsageLimiter — enforces free-tier quota.
//
// Checked by PronunciationService BEFORE the provider call, so a blocked request costs no
// Azure money. This is a COST CONTROL as much as a monetization lever.
//
// MVP counts attempts per user per local day from an indexed column; Stage 2 moves the
// counter to CacheStore (Redis) without changing this interface.
//
// Limits come from configuration (FREE_DAILY_ASSESSMENT_LIMIT), never from literals, so
// pricing experiments do not require a release.
//
// A FAILED attempt must NOT consume quota — we do not charge users for our outages.
//
// See ARCHITECTURE.md 9.4, 6.5, 20.3.

package subscription
