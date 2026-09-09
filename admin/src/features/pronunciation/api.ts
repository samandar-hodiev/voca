// pronunciation: backend API calls.
//
// Pronunciation and phoneme analytics across the user base: score distributions, common weak sounds, provider quality signals.
//
// This is the ONLY place in the feature that talks to the network. Components and hooks call
// these functions; they never call fetch directly.
//
// Every call goes through src/services/apiClient.ts, which attaches the admin session and
// maps the backend error envelope. The admin NEVER queries PostgreSQL and never reimplements
// a business rule the backend already owns (ARCHITECTURE.md 38.4, 39.3, ADR-014).
