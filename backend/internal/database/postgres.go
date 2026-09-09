// database: PostgreSQL connection pool (pgxpool).
//
// Builds the pool from DATABASE_URL with DATABASE_MAX_CONNS, sets sane timeouts, and
// exposes a health check used by GET /readyz.
//
// Connection count becomes the limiting factor before CPU does, which is why PgBouncer
// appears at Stage 3 (ARCHITECTURE.md 33).

package database
