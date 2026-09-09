// Route registration for the devhook module.
package devhook

import "github.com/gin-gonic/gin"

// RegisterRoutes mounts the webhook endpoints on the given /api/v1 group.
//
// The webhook is NOT behind RequireAuth: GitHub cannot present a Voca JWT. It is
// authenticated by HMAC signature instead (ARCHITECTURE.md 9.5 uses the same pattern for
// the RevenueCat webhook).
func RegisterRoutes(v1 *gin.RouterGroup, h *Handler) {
	webhooks := v1.Group("/webhooks")
	webhooks.POST("/github", h.GitHubWebhook)
}
