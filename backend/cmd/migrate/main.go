// Migration runner.
//
// Applies or rolls back versioned SQL migrations from backend/migrations against
// DATABASE_URL. Run as a distinct deployment step BEFORE the new image serves traffic.
//
// NOT IMPLEMENTED YET: the database layer arrives at implementation step 2 of
// ARCHITECTURE.md 37. This entrypoint exists so the package compiles and so the command
// reports its own status honestly rather than failing obscurely.
package main

import "fmt"

func main() {
	fmt.Println("voca migrate: not implemented yet.")
	fmt.Println("Migrations arrive with the database layer; see docs/architecture/ARCHITECTURE.md section 37.")
}
