// Authentication middleware.
//
// SCAFFOLD ONLY. Token verification is deliberately NOT implemented in this task: the
// token model, Apple and Google verification, and refresh rotation are designed in
// ARCHITECTURE.md 8 and belong to the authentication task.
//
// What exists here is the seam: the interface a verifier must satisfy, and the middleware
// that puts an authenticated user ID into the request context. Wiring a real verifier
// later changes one constructor call and nothing else.
//
// Authentication ONLY. Resource ownership is checked in the service layer and is never
// inferred from the URL; a request for another user's resource returns 404, not 403, so
// identifiers cannot be probed (ARCHITECTURE.md 8.5).
package middleware

import (
	"context"
	"strings"

	"github.com/gin-gonic/gin"

	"github.com/samandar-hodiev/voca/backend/internal/shared/apperr"
	"github.com/samandar-hodiev/voca/backend/internal/shared/ctxutil"
	"github.com/samandar-hodiev/voca/backend/internal/shared/httpx"
)

// TokenVerifier turns a bearer token into a user ID.
//
// The port is owned by the consumer, not by whatever library ends up implementing it
// (ARCHITECTURE.md 7.1, ADR-006).
type TokenVerifier interface {
	// VerifyAccessToken returns the subject of a valid token, or an error.
	VerifyAccessToken(ctx context.Context, token string) (userID string, err error)
}

// RequireAuth rejects a request that does not carry a valid bearer token.
//
// Not mounted on any route yet; no route in this foundation requires authentication.
func RequireAuth(verifier TokenVerifier) gin.HandlerFunc {
	return func(c *gin.Context) {
		token, ok := bearerToken(c)
		if !ok {
			httpx.FailWith(c, apperr.Unauthenticated("Authentication required."))
			return
		}

		userID, err := verifier.VerifyAccessToken(c.Request.Context(), token)
		if err != nil {
			// The reason is never returned: telling a caller why a token was rejected
			// helps them craft one that is accepted.
			httpx.FailWith(c, apperr.Unauthenticated("Authentication required."))
			return
		}

		c.Request = c.Request.WithContext(ctxutil.WithUserID(c.Request.Context(), userID))
		c.Next()
	}
}

func bearerToken(c *gin.Context) (string, bool) {
	header := c.GetHeader("Authorization")
	if header == "" {
		return "", false
	}
	const prefix = "Bearer "
	if len(header) <= len(prefix) || !strings.EqualFold(header[:len(prefix)], prefix) {
		return "", false
	}
	token := strings.TrimSpace(header[len(prefix):])
	return token, token != ""
}
