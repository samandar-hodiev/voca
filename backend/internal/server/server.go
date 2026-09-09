// server: HTTP server lifecycle.
//
// Builds http.Server with sane timeouts (read, write, idle, header), starts it, and
// implements graceful shutdown.
//
// Also hosts the operational endpoints:
//   GET /healthz  liveness — the process is up
//   GET /readyz   readiness — database reachable, configuration valid, migrations applied
//
// The platform uses these for rolling deploys and restarts, so they must be cheap and must
// not require authentication.
//
// See ARCHITECTURE.md 11.2 (system endpoints), 24.4.

package server
