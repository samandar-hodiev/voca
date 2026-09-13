// progress: route registration on the /api/v1 router group.
//
// One read, and it requires a session: a dashboard is somebody's own history.
//
// See ARCHITECTURE.md 11.2 (endpoint contracts) and 30 (endpoint map).

package progress

import "github.com/gin-gonic/gin"

func RegisterRoutes(v1 *gin.RouterGroup, h *Handler, requireAuth gin.HandlerFunc) {
	g := v1.Group("/progress", requireAuth)
	{
		g.GET("/summary", h.Summary)
	}
}
