// Migration runner.
//
// Applies every pending migration against DATABASE_URL. Run as a distinct deployment step
// BEFORE the new image serves traffic (ARCHITECTURE.md 24.4).
package main

import (
	"fmt"
	"os"

	"github.com/samandar-hodiev/voca/backend/internal/config"
	"github.com/samandar-hodiev/voca/backend/internal/database"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		fail(err)
	}

	if err := database.Migrate(cfg.DatabaseURL); err != nil {
		fail(err)
	}

	fmt.Println("migrations applied")
}

func fail(err error) {
	// The error never contains the connection string; see database.Open.
	fmt.Fprintln(os.Stderr, "voca migrate:", err)
	os.Exit(1)
}
