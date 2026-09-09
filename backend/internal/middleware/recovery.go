// Panic recovery middleware.
//
// Converts a panic into 500 INTERNAL_ERROR carrying the request ID. The stack trace is
// logged server-side and NEVER returned to the client, along with driver messages, table
// names and constraint names (ARCHITECTURE.md 18.2, 19.3).
package middleware

import (
	"log/slog"
	"net/http"
	"runtime/debug"

	"github.com/gin-gonic/gin"

	"github.com/samandar-hodiev/voca/backend/internal/shared/httpx"
)

// Recovery keeps one bad request from taking down the process.
func Recovery(log *slog.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if r := recover(); r != nil {
				log.Error("panic_recovered",
					slog.String("request_id", httpx.RequestID(c)),
					slog.String("path", c.FullPath()),
					slog.Any("panic", r),
					slog.String("stack", string(debug.Stack())),
				)
				httpx.Fail(c, http.StatusInternalServerError, "INTERNAL_ERROR",
					"An unexpected error occurred.")
			}
		}()
		c.Next()
	}
}
