// pkg/idgen: UUID generation.
//
// Time-ordered UUIDs (v7-style) preferred over v4: they index better in PostgreSQL, are
// non-enumerable in URLs, and merge cleanly if data is ever split across services.
//
// See ARCHITECTURE.md 10 (key conventions).

package idgen
