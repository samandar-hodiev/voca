// word: route registration on the /api/v1 router group.
//
// Content is readable by any signed-in learner and writable by nobody: authoring arrives
// with the admin tool, and until then the seed is the only way in (ARCHITECTURE.md 13.4).
//
// See ARCHITECTURE.md 11.2 (endpoint contracts) and 30 (endpoint map).

package word

import "github.com/gin-gonic/gin"

func RegisterRoutes(v1 *gin.RouterGroup, h *Handler, requireAuth gin.HandlerFunc) {
	v1.GET("/categories", requireAuth, h.Categories)

	g := v1.Group("/words", requireAuth)
	{
		g.GET("", h.List)
		g.GET("/:id", h.Get)
	}
}
