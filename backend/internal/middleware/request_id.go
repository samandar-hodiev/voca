// Request ID middleware.
//
// Accepts X-Request-ID from the client or generates one, stores it in the gin context,
// and echoes it in the response header. The same value is attached to every log line, so
// a request ID from a user's screenshot maps directly to a log entry
// (ARCHITECTURE.md 18.4).
package middleware

import (
	"crypto/rand"
	"encoding/hex"

	"github.com/gin-gonic/gin"

	"github.com/samandar-hodiev/voca/backend/internal/shared/httpx"
)

const requestIDHeader = "X-Request-ID"

// RequestID ensures every request carries a correlation identifier.
func RequestID() gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.GetHeader(requestIDHeader)
		if id == "" {
			id = newRequestID()
		}
		c.Set(httpx.ContextRequestIDKey, id)
		c.Writer.Header().Set(requestIDHeader, id)
		c.Next()
	}
}

func newRequestID() string {
	b := make([]byte, 16)
	if _, err := rand.Read(b); err != nil {
		return "unknown"
	}
	return hex.EncodeToString(b)
}
