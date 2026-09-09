// auth: backend API calls.
//
// Admin sign-in, session handling, and the current admin's role. Authentication is performed BY THE BACKEND; this feature only carries credentials and stores the session.
//
// This is the ONLY place in the feature that talks to the network. Components and hooks call
// these functions; they never call fetch directly.
//
// Every call goes through src/services/apiClient.ts, which attaches the admin session and
// maps the backend error envelope. The admin NEVER queries PostgreSQL and never reimplements
// a business rule the backend already owns (ARCHITECTURE.md 38.4, 39.3, ADR-014).
