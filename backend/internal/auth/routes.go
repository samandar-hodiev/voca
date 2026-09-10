// Route registration for the auth module.
package auth

import "github.com/gin-gonic/gin"

// RegisterRoutes mounts the auth endpoints on the /api/v1 group.
//
// requireAuth is injected rather than imported so this package does not depend on the
// middleware package, which would create a cycle once middleware needs a verifier built
// from this module.
func RegisterRoutes(v1 *gin.RouterGroup, h *Handler, requireAuth gin.HandlerFunc) {
	a := v1.Group("/auth")
	{
		a.POST("/email/start", h.StartEmailVerification)
		a.POST("/email/verify", h.VerifyEmail)
		a.POST("/email/resend", h.ResendEmailVerification)

		a.POST("/register", h.Register)
		a.POST("/login", h.Login)
		a.POST("/guest", h.Guest)

		a.POST("/refresh", h.Refresh)
		a.POST("/logout", h.Logout)

		a.POST("/password/forgot", h.ForgotPassword)
		a.POST("/password/verify", h.VerifyPasswordCode)
		a.POST("/password/reset", h.ResetPassword)
	}

	// Preferences belong to a signed-in person, so they sit behind authentication.
	me := v1.Group("/users/me", requireAuth)
	{
		me.GET("/preferences", h.GetPreferences)
		me.PUT("/preferences", h.UpdatePreferences)
	}
}
