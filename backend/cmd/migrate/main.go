// Migration runner.
//
// Applies or rolls back versioned SQL migrations from backend/migrations against
// DATABASE_URL. Run as a distinct deployment step BEFORE the new image serves traffic.
//
// Migrations must be forward-compatible so that old and new instances can run side by side
// during a rolling deploy — ARCHITECTURE.md 24.4.

package main
