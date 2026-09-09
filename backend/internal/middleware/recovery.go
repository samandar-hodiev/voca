// middleware: panic recovery.
//
// Converts a panic into 500 INTERNAL_ERROR with the request ID. Logs the stack trace
// server-side; NEVER returns a stack trace, driver message, table name, or constraint name
// to the client.
//
// See ARCHITECTURE.md 18.2, 19.3.

package middleware
