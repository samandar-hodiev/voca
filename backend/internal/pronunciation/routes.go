// pronunciation: route registration on the /api/v1 router group.
//
// Both routes require a session: an attempt belongs to an account, and history is that
// account's own. Submitting is rate limited because it is the one endpoint that spends
// provider money.
//
// See ARCHITECTURE.md 11.2 (endpoint contracts) and 30 (endpoint map).

package pronunciation

import "github.com/gin-gonic/gin"

func RegisterRoutes(v1 *gin.RouterGroup, h *Handler,
	requireAuth gin.HandlerFunc, rateLimit gin.HandlerFunc) {

	g := v1.Group("/pronunciation", requireAuth)
	if rateLimit != nil {
		g.Use(rateLimit)
	}
	{
		g.POST("/attempts", h.SubmitAttempt)
		g.GET("/attempts", h.History)
	}
}
