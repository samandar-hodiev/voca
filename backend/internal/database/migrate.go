// Migration runner.
//
// Migrations are embedded in the binary, so the image that applies them is the image that
// carries them and a deploy can never run one image's code against another's schema.
package database

import (
	"database/sql"
	"errors"
	"fmt"

	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/postgres"
	"github.com/golang-migrate/migrate/v4/source/iofs"
	_ "github.com/jackc/pgx/v5/stdlib"

	"github.com/samandar-hodiev/voca/backend/migrations"
)

// Migrate applies every pending migration.
//
// It opens its OWN short-lived connection rather than borrowing the application pool.
// Sharing the pool means golang-migrate holds a connection for the whole run and the
// pool's own Close then waits on it forever.
func Migrate(databaseURL string) error {
	source, err := iofs.New(migrations.FS, ".")
	if err != nil {
		return fmt.Errorf("database: read migrations: %w", err)
	}

	db, err := sql.Open("pgx", databaseURL)
	if err != nil {
		return fmt.Errorf("database: open for migrations: %w", err)
	}
	defer db.Close()

	driver, err := postgres.WithInstance(db, &postgres.Config{})
	if err != nil {
		return fmt.Errorf("database: migration driver: %w", err)
	}

	m, err := migrate.NewWithInstance("iofs", source, "postgres", driver)
	if err != nil {
		return fmt.Errorf("database: migrator: %w", err)
	}

	if err := m.Up(); err != nil && !errors.Is(err, migrate.ErrNoChange) {
		return fmt.Errorf("database: apply migrations: %w", err)
	}
	return nil
}
