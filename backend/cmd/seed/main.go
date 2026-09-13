// Content seed loader.
//
// Applies every SQL file in backend/migrations/seed in filename order, inside one
// transaction per file. Seed files are separate from migrations on purpose: a schema
// change must run before the new image serves traffic, whereas content can be reloaded at
// any time and in any environment (ARCHITECTURE.md 13.4).
//
// Every seed file must be safe to run twice. The word seed is, through
// ON CONFLICT DO NOTHING on the natural key, which is what makes "reload the content"
// an ordinary operation rather than a risk.
package main

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"time"

	"github.com/samandar-hodiev/voca/backend/internal/config"
	"github.com/samandar-hodiev/voca/backend/internal/database"
)

// seedDir is relative to the backend module root, which is where this is run from.
const seedDir = "migrations/seed"

func main() {
	cfg, err := config.Load()
	if err != nil {
		fail(err)
	}

	files, err := filepath.Glob(filepath.Join(seedDir, "*.sql"))
	if err != nil {
		fail(err)
	}
	if len(files) == 0 {
		fmt.Println("voca seed: no seed files found in", seedDir)
		return
	}
	sort.Strings(files)

	// Generous: the word seed is a single statement with thousands of rows.
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	pool, err := database.Open(ctx, database.Config{URL: cfg.DatabaseURL})
	if err != nil {
		fail(err)
	}
	defer pool.Close()

	for _, path := range files {
		sql, err := os.ReadFile(path)
		if err != nil {
			fail(err)
		}

		// One transaction per file: a half-applied content set is harder to reason about
		// than one that failed cleanly.
		tx, err := pool.Begin(ctx)
		if err != nil {
			fail(err)
		}
		if _, err := tx.Exec(ctx, string(sql)); err != nil {
			_ = tx.Rollback(ctx)
			fail(fmt.Errorf("%s: %w", filepath.Base(path), err))
		}
		if err := tx.Commit(ctx); err != nil {
			fail(err)
		}
		fmt.Println("applied", filepath.Base(path))
	}

	fmt.Println("seed complete")
}

func fail(err error) {
	// The error never contains the connection string; see database.Open.
	fmt.Fprintln(os.Stderr, "voca seed:", err)
	os.Exit(1)
}
