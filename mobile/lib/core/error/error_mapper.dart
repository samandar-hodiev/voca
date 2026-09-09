// core/error: maps the backend error CODE to a Failure, and a Failure to localized text.
//
// The app localizes by CODE, never by the server's message string — which is why the API
// can return English messages and a second UI language costs no backend work
// (ARCHITECTURE.md 19.1, 19.3).
//
// USAGE_LIMIT_REACHED and PREMIUM_REQUIRED map to DIFFERENT screens: come back tomorrow or
// upgrade, versus not in your plan. Do not collapse them.
