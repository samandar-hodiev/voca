// CORS middleware.
//
// The mobile app is not a browser and needs no CORS. This exists for the admin dashboard
// and local tooling, which do run in a browser (ARCHITECTURE.md 18.2, 38.4).
//
// Origins come from configuration and default to nothing, so an unconfigured deployment
// permits no cross-origin request rather than permitting every one.
package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

// CORSConfig lists the origins allowed to call this API from a browser.
type CORSConfig struct {
	AllowedOrigins []string
}

// CORS answers preflight requests and sets the response headers for allowed origins.
//
// Origins are matched exactly. There is deliberately no wildcard and no pattern matching:
// this API serves credentialed requests, and "*" cannot be combined with credentials
// without effectively disabling the protection.
func CORS(cfg CORSConfig) gin.HandlerFunc {
	allowed := make(map[string]struct{}, len(cfg.AllowedOrigins))
	for _, o := range cfg.AllowedOrigins {
		if o = strings.TrimSpace(o); o != "" {
			allowed[o] = struct{}{}
		}
	}

	return func(c *gin.Context) {
		origin := c.GetHeader("Origin")

		// Not a cross-origin request; nothing to negotiate.
		if origin == "" {
			c.Next()
			return
		}

		if _, ok := allowed[origin]; !ok {
			// Unknown origin: send no CORS headers at all and let the browser refuse.
			// A preflight still ends here rather than reaching a handler.
			if c.Request.Method == http.MethodOptions {
				c.AbortWithStatus(http.StatusForbidden)
				return
			}
			c.Next()
			return
		}

		h := c.Writer.Header()
		h.Set("Access-Control-Allow-Origin", origin)
		h.Set("Access-Control-Allow-Credentials", "true")
		h.Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
		h.Set("Access-Control-Allow-Headers",
			"Authorization, Content-Type, X-Request-ID, X-App-Version, X-Platform, Idempotency-Key")
		h.Set("Access-Control-Expose-Headers", "X-Request-ID, Retry-After")
		h.Set("Access-Control-Max-Age", "600")

		// Responses differ per origin, so caches must not reuse one origin's response
		// for another.
		h.Add("Vary", "Origin")

		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}
