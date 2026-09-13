// practice: route registration on the /api/v1 router group.
//
// Every route requires a session: a practice set belongs to somebody.
//
// POST and GET on /sessions/current are the same operation — "give me the set I owe" —
// because creating today's set is idempotent. The app calls it on every open.
//
// See ARCHITECTURE.md 11.2 (endpoint contracts) and 30 (endpoint map).

package practice

import "github.com/gin-gonic/gin"

func RegisterRoutes(v1 *gin.RouterGroup, h *Handler, requireAuth gin.HandlerFunc) {
	g := v1.Group("/practice", requireAuth)
	{
		g.POST("/sessions", h.Current)
		g.GET("/sessions/current", h.Current)
		g.POST("/sessions/:id/complete", h.Complete)
		g.GET("/week", h.Week)
	}
}
