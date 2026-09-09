// Router assembly.
//
// Installs the middleware chain in order, then mounts each module's routes under the
// /api/v1 group. A future /api/v2 is a SECOND GROUP reusing the same services, which is
// what lets both versions run in one binary while old app versions drain
// (ARCHITECTURE.md 11.1, ADR-009).
package server

import (
	"log/slog"
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/samandar-hodiev/voca/backend/internal/devhook"
	"github.com/samandar-hodiev/voca/backend/internal/middleware"
	"github.com/samandar-hodiev/voca/backend/internal/shared/httpx"
)

// Dependencies is the set of built modules the router mounts.
type Dependencies struct {
	Logger         *slog.Logger
	DevhookHandler *devhook.Handler
}

// NewRouter builds the HTTP router.
func NewRouter(deps Dependencies) *gin.Engine {
	r := gin.New()

	r.Use(
		middleware.RequestID(),
		middleware.Recovery(deps.Logger),
		middleware.Logger(deps.Logger),
	)

	// Operational endpoints sit outside /api/v1: they are infrastructure, not product,
	// and the platform calls them for rolling deploys and restarts.
	r.GET("/health", health)
	r.GET("/healthz", health)

	v1 := r.Group("/api/v1")
	devhook.RegisterRoutes(v1, deps.DevhookHandler)

	return r
}

// health reports that the process is up.
//
// It deliberately does NOT touch the database: liveness must stay cheap and must not fail
// because a dependency is briefly unavailable. A dependency-aware readiness check belongs
// on /readyz, which arrives with the database (ARCHITECTURE.md 11.2, 24.4).
func health(c *gin.Context) {
	httpx.OK(c, http.StatusOK, gin.H{"status": "ok"})
}
