// Voca API entrypoint.
//
// Responsibility, in order: load and validate configuration (fail fast on anything
// missing), build the logger, open the pgx pool, construct the whole object graph via
// internal/server/wire.go, start the HTTP server, and handle SIGTERM for graceful shutdown
// (stop accepting connections, drain in-flight requests, close the pool).
//
// Graceful shutdown is not optional: it is what makes zero-downtime rolling deploys work.
//
// Keep this file thin. It wires and starts; it decides nothing.
//
// See ARCHITECTURE.md 5.7, 24.4.

package main
