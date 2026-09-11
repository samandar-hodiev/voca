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

	"github.com/samandar-hodiev/voca/backend/internal/auth"
	"github.com/samandar-hodiev/voca/backend/internal/database"
	"github.com/samandar-hodiev/voca/backend/internal/devhook"
	"github.com/samandar-hodiev/voca/backend/internal/middleware"
	"github.com/samandar-hodiev/voca/backend/internal/shared/httpx"
)

// Dependencies is the set of built modules the router mounts.
type Dependencies struct {
	Logger         *slog.Logger
	CORS           middleware.CORSConfig
	DevhookHandler *devhook.Handler
	AuthHandler    *auth.Handler
	Capabilities   Capabilities
	RequireAuth    gin.HandlerFunc
	AuthRateLimit  gin.HandlerFunc

	// TrustedProxies are the only addresses whose X-Forwarded-For is believed. Nil
	// trusts none.
	TrustedProxies []string
	DB             *database.Pool

	// AvatarDir and AvatarPrefix let the router serve uploaded pictures back. Serving
	// them from the API keeps the MVP to one process; a CDN in front of object storage
	// replaces both without the app noticing, because the stored URL is a path.
	AvatarDir    string
	AvatarPrefix string
}

// avatarURLPrefix is the path uploaded pictures are served under.
const avatarURLPrefix = "/media/avatars"

// Capabilities tells the client which optional sign-in methods actually work.
//
// The app reads this at startup and disables what is unavailable, so a button that cannot
// succeed is never offered.
type Capabilities struct {
	GoogleSignIn bool `json:"google_sign_in"`
	AppleSignIn  bool `json:"apple_sign_in"`
}

// NewRouter builds the HTTP router.
func NewRouter(deps Dependencies) *gin.Engine {
	r := gin.New()

	// Gin trusts every proxy unless told otherwise, which means ClientIP returns whatever a
	// caller writes in X-Forwarded-For. The per-client rate limit keys on ClientIP, so with
	// the default any caller gets a fresh bucket per request by rotating that header, and
	// the limit ADR-018 depends on does nothing. Trust only what is configured.
	if err := r.SetTrustedProxies(deps.TrustedProxies); err != nil {
		deps.Logger.Error("trusted_proxies_invalid",
			slog.String("error", err.Error()),
			slog.String("fallback", "trusting no proxy"))
		_ = r.SetTrustedProxies(nil)
	}

	// Order matters. RequestID first so every later line and every error carries a
	// correlation ID. Recovery before Logger so a panic is still logged as a request.
	// CORS before routing so a preflight never reaches a handler.
	r.Use(
		middleware.RequestID(),
		middleware.Recovery(deps.Logger),
		middleware.Logger(deps.Logger),
		middleware.CORS(deps.CORS),
	)

	// Operational endpoints sit outside /api/v1: they are infrastructure, not product,
	// and the platform calls them for rolling deploys and restarts.
	r.GET("/health", health)
	r.GET("/healthz", health)

	// Uploaded pictures. Outside /api/v1 because they are files rather than API
	// resources, and unauthenticated because an avatar is shown next to a name: putting
	// it behind a token would mean every screen that lists people needs one per image.
	// The stored name carries random bytes, so a URL cannot be guessed from an account id.
	if deps.AvatarDir != "" && deps.AvatarPrefix != "" {
		r.Static(deps.AvatarPrefix, deps.AvatarDir)
	}

	v1 := r.Group("/api/v1")
	devhook.RegisterRoutes(v1, deps.DevhookHandler)
	auth.RegisterRoutes(v1, deps.AuthHandler, deps.RequireAuth, deps.AuthRateLimit)

	// Remote configuration: feature availability the client cannot know on its own.
	v1.GET("/config", func(c *gin.Context) {
		httpx.OK(c, http.StatusOK, gin.H{"capabilities": deps.Capabilities})
	})

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
