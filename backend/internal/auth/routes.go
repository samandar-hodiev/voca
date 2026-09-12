// Route registration for the auth module.
package auth

import "github.com/gin-gonic/gin"

// RegisterRoutes mounts the auth endpoints on the /api/v1 group.
//
// requireAuth is injected rather than imported so this package does not depend on the
// middleware package, which would create a cycle once middleware needs a verifier built
// from this module.
func RegisterRoutes(v1 *gin.RouterGroup, h *Handler,
	requireAuth gin.HandlerFunc, rateLimit gin.HandlerFunc) {

	// Everything under /auth is rate limited. These are the endpoints where guessing is
	// the attack: passwords, codes, and whether an address is registered at all.
	a := v1.Group("/auth")
	if rateLimit != nil {
		a.Use(rateLimit)
	}
	{
		a.POST("/email/start", h.StartEmailVerification)
		a.POST("/email/verify", h.VerifyEmail)
		a.POST("/email/resend", h.ResendEmailVerification)

		a.POST("/register", h.Register)
		a.POST("/login", h.Login)
		a.POST("/guest", h.Guest)
		a.POST("/google", h.Google)

		a.POST("/refresh", h.Refresh)
		a.POST("/logout", h.Logout)

		a.POST("/password/forgot", h.ForgotPassword)
		a.POST("/password/verify", h.VerifyPasswordCode)
		a.POST("/password/reset", h.ResetPassword)
	}

	// Preferences belong to a signed-in person, so they sit behind authentication.
	me := v1.Group("/users/me", requireAuth)
	{
		me.GET("", h.Me)
		me.GET("/preferences", h.GetPreferences)
		me.PUT("/preferences", h.UpdatePreferences)
		me.POST("/avatar", h.UploadAvatar)
	}

	// Signing out is confirmed with a code sent to the account's own address. It needs a
	// signed-in person, and it is rate limited like the other code endpoints, because the
	// code is the thing somebody would try to guess.
	signOut := v1.Group("/users/me/sign-out", requireAuth)
	if rateLimit != nil {
		signOut.Use(rateLimit)
	}
	{
		signOut.POST("/start", h.StartSignOut)
		signOut.POST("/confirm", h.ConfirmSignOut)
	}

	// Deleting an account is confirmed the same way, and for the same reason: the code is
	// the thing an attacker with a stolen token would have to guess. Kept separate from
	// sign-out so neither flow's code can stand in for the other's.
	deleteAccount := v1.Group("/users/me/delete", requireAuth)
	if rateLimit != nil {
		deleteAccount.Use(rateLimit)
	}
	{
		deleteAccount.POST("/start", h.StartAccountDeletion)
		deleteAccount.POST("/confirm", h.ConfirmAccountDeletion)
	}
}
