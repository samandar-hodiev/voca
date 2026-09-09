// Structured request logging (log/slog, JSON).
//
// Every line carries: request_id, method, path, status, duration_ms.
//
// NEVER LOGGED: passwords, access or refresh tokens, identity tokens, API keys or
// secrets, webhook signatures, raw audio, email addresses, or request bodies for auth and
// upload endpoints. That list is a hard rule, not a guideline (ARCHITECTURE.md 18.4).
package middleware

import (
	"log/slog"
	"time"

	"github.com/gin-gonic/gin"

	"github.com/samandar-hodiev/voca/backend/internal/shared/httpx"
)

// Logger records one structured line per request.
func Logger(log *slog.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		c.Next()

		// Query strings are deliberately excluded: they can carry user data.
		log.Info("http_request",
			slog.String("request_id", httpx.RequestID(c)),
			slog.String("method", c.Request.Method),
			slog.String("path", c.FullPath()),
			slog.Int("status", c.Writer.Status()),
			slog.Int64("duration_ms", time.Since(start).Milliseconds()),
		)
	}
}
