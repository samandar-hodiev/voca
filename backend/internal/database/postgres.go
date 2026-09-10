// PostgreSQL connection pool.
//
// pgx is used directly rather than through database/sql: it speaks the native protocol,
// handles PostgreSQL types properly, and its pool is what the rest of the backend expects
// (ARCHITECTURE.md 5.6).
package database

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Config describes how to reach the database.
type Config struct {
	URL      string
	MaxConns int32
}

// Pool wraps the connection pool.
type Pool struct {
	*pgxpool.Pool
}

// Open creates and verifies the pool.
//
// The connection is checked here rather than lazily on the first query, so a bad
// DATABASE_URL fails at startup instead of surfacing as a confusing error during someone
// else's request.
func Open(ctx context.Context, cfg Config) (*Pool, error) {
	poolCfg, err := pgxpool.ParseConfig(cfg.URL)
	if err != nil {
		// The URL contains the password, so it is never included in the error.
		return nil, fmt.Errorf("database: invalid DATABASE_URL")
	}

	if cfg.MaxConns > 0 {
		poolCfg.MaxConns = cfg.MaxConns
	}
	poolCfg.MaxConnLifetime = time.Hour
	poolCfg.MaxConnIdleTime = 30 * time.Minute

	pool, err := pgxpool.NewWithConfig(ctx, poolCfg)
	if err != nil {
		return nil, fmt.Errorf("database: create pool: %w", err)
	}

	pingCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	if err := pool.Ping(pingCtx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("database: cannot reach the database: %w", err)
	}

	return &Pool{pool}, nil
}

// Health reports whether the database is reachable. Used by the readiness endpoint.
func (p *Pool) Health(ctx context.Context) error {
	ctx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()
	return p.Ping(ctx)
}
