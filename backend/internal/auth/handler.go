// HTTP handlers for authentication. THIN LAYER — no business logic.
//
// Each handler binds a request, calls exactly one service method, and maps the result to
// HTTP. Every rule lives in the service (ARCHITECTURE.md 5.3).
package auth

import (
	"io"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/samandar-hodiev/voca/backend/internal/shared/apperr"
	"github.com/samandar-hodiev/voca/backend/internal/shared/ctxutil"
	"github.com/samandar-hodiev/voca/backend/internal/shared/httpx"
)

// Handler serves the auth endpoints.
type Handler struct {
	svc *Service
}

// NewHandler builds the handler.
func NewHandler(svc *Service) *Handler { return &Handler{svc: svc} }

func bind[T any](c *gin.Context) (T, bool) {
	var req T
	if err := c.ShouldBindJSON(&req); err != nil {
		httpx.FailWith(c, apperr.InvalidBody("The request could not be read."))
		var zero T
		return zero, false
	}
	return req, true
}

// StartEmailVerification handles POST /auth/email/start.
func (h *Handler) StartEmailVerification(c *gin.Context) {
	req, ok := bind[emailRequest](c)
	if !ok {
		return
	}
	if err := h.svc.StartEmailVerification(c.Request.Context(), req.Email); err != nil {
		httpx.FailWith(c, err)
		return
	}
	// Deliberately says only that the request was accepted: whether an account exists is
	// not disclosed.
	httpx.OK(c, http.StatusOK, gin.H{"status": "sent"})
}

// ResendEmailVerification handles POST /auth/email/resend. Same behaviour as start; the
// rate limit inside the service is what makes resending safe.
func (h *Handler) ResendEmailVerification(c *gin.Context) {
	h.StartEmailVerification(c)
}

// VerifyEmail handles POST /auth/email/verify.
func (h *Handler) VerifyEmail(c *gin.Context) {
	req, ok := bind[verifyCodeRequest](c)
	if !ok {
		return
	}
	if err := h.svc.VerifyCode(c.Request.Context(), req.Email, PurposeSignup, req.Code); err != nil {
		httpx.FailWith(c, err)
		return
	}
	httpx.OK(c, http.StatusOK, gin.H{"status": "verified"})
}

// Register handles POST /auth/register.
func (h *Handler) Register(c *gin.Context) {
	req, ok := bind[registerRequest](c)
	if !ok {
		return
	}
	session, err := h.svc.Register(c.Request.Context(), RegisterInput{
		Email: req.Email, Password: req.Password,
		FirstName: req.FirstName, LastName: req.LastName,
		Phone: req.Phone, AvatarURL: req.AvatarURL,
		CEFRLevel: req.CEFRLevel, LearningGoal: req.LearningGoal,
		DailyGoalWords: req.DailyGoalWords, Timezone: req.Timezone,
	})
	if err != nil {
		httpx.FailWith(c, err)
		return
	}
	// Registration establishes a session directly: asking someone to sign in immediately
	// after creating an account is friction with no security benefit.
	httpx.OK(c, http.StatusCreated, toSessionResponse(session))
}

// Login handles POST /auth/login.
func (h *Handler) Login(c *gin.Context) {
	req, ok := bind[loginRequest](c)
	if !ok {
		return
	}
	session, err := h.svc.Login(c.Request.Context(), req.Email, req.Password)
	if err != nil {
		httpx.FailWith(c, err)
		return
	}
	httpx.OK(c, http.StatusOK, toSessionResponse(session))
}

// Guest handles POST /auth/guest.
func (h *Handler) Guest(c *gin.Context) {
	req, _ := bind[guestRequest](c)
	session, err := h.svc.CreateGuest(c.Request.Context(), RegisterInput{
		CEFRLevel: req.CEFRLevel, LearningGoal: req.LearningGoal,
		DailyGoalWords: req.DailyGoalWords,
	})
	if err != nil {
		httpx.FailWith(c, err)
		return
	}
	httpx.OK(c, http.StatusCreated, toSessionResponse(session))
}

// Google handles POST /auth/google.
func (h *Handler) Google(c *gin.Context) {
	req, ok := bind[googleSignInRequest](c)
	if !ok {
		return
	}
	session, err := h.svc.SignInWithGoogle(c.Request.Context(), req.IDToken, RegisterInput{
		FirstName: req.FirstName, LastName: req.LastName,
		CEFRLevel: req.CEFRLevel, LearningGoal: req.LearningGoal,
		DailyGoalWords: req.DailyGoalWords,
	})
	if err != nil {
		httpx.FailWith(c, err)
		return
	}
	httpx.OK(c, http.StatusOK, toSessionResponse(session))
}

// Refresh handles POST /auth/refresh.
func (h *Handler) Refresh(c *gin.Context) {
	req, ok := bind[refreshRequest](c)
	if !ok {
		return
	}
	session, err := h.svc.Refresh(c.Request.Context(), req.RefreshToken)
	if err != nil {
		httpx.FailWith(c, err)
		return
	}
	httpx.OK(c, http.StatusOK, toSessionResponse(session))
}

// Logout handles POST /auth/logout.
func (h *Handler) Logout(c *gin.Context) {
	req, ok := bind[refreshRequest](c)
	if !ok {
		return
	}
	if err := h.svc.Logout(c.Request.Context(), req.RefreshToken); err != nil {
		httpx.FailWith(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

// ForgotPassword handles POST /auth/password/forgot.
func (h *Handler) ForgotPassword(c *gin.Context) {
	req, ok := bind[emailRequest](c)
	if !ok {
		return
	}
	if err := h.svc.StartPasswordReset(c.Request.Context(), req.Email); err != nil {
		httpx.FailWith(c, err)
		return
	}
	httpx.OK(c, http.StatusOK, gin.H{"status": "sent"})
}

// VerifyPasswordCode handles POST /auth/password/verify.
func (h *Handler) VerifyPasswordCode(c *gin.Context) {
	req, ok := bind[verifyCodeRequest](c)
	if !ok {
		return
	}
	if err := h.svc.VerifyCode(c.Request.Context(), req.Email, PurposePasswordReset, req.Code); err != nil {
		httpx.FailWith(c, err)
		return
	}
	httpx.OK(c, http.StatusOK, gin.H{"status": "verified"})
}

// ResetPassword handles POST /auth/password/reset.
func (h *Handler) ResetPassword(c *gin.Context) {
	req, ok := bind[resetPasswordRequest](c)
	if !ok {
		return
	}
	session, err := h.svc.ResetPassword(c.Request.Context(), req.Email, req.Password)
	if err != nil {
		httpx.FailWith(c, err)
		return
	}
	httpx.OK(c, http.StatusOK, toSessionResponse(session))
}

// GetPreferences handles GET /users/me/preferences.
func (h *Handler) GetPreferences(c *gin.Context) {
	userID, ok := currentUser(c)
	if !ok {
		return
	}
	prefs, err := h.svc.Preferences(c.Request.Context(), userID)
	if err != nil {
		httpx.FailWith(c, err)
		return
	}
	httpx.OK(c, http.StatusOK, toPreferencesResponse(prefs))
}

// UpdatePreferences handles PUT /users/me/preferences.
func (h *Handler) UpdatePreferences(c *gin.Context) {
	userID, ok := currentUser(c)
	if !ok {
		return
	}
	req, bound := bind[preferencesRequest](c)
	if !bound {
		return
	}

	daily := 0
	if req.DailyGoalWords != nil {
		daily = *req.DailyGoalWords
	}
	tz := ""
	if req.Timezone != nil {
		tz = *req.Timezone
	}

	if err := h.svc.SavePreferences(c.Request.Context(), userID, Preferences{
		CEFRLevel: req.CEFRLevel, LearningGoal: req.LearningGoal,
		DailyGoalWords: daily, Timezone: tz,
	}); err != nil {
		httpx.FailWith(c, err)
		return
	}

	prefs, err := h.svc.Preferences(c.Request.Context(), userID)
	if err != nil {
		httpx.FailWith(c, err)
		return
	}
	httpx.OK(c, http.StatusOK, toPreferencesResponse(prefs))
}

// UploadAvatar stores a profile picture for the signed-in person.
//
// Multipart rather than JSON, because base64 inside a JSON body inflates an image by a
// third and forces the whole thing into memory twice.
func (h *Handler) UploadAvatar(c *gin.Context) {
	userID, ok := currentUser(c)
	if !ok {
		return
	}

	// Bound what will be read before reading it. Without this a client can stream an
	// arbitrarily large body and the server will hold all of it.
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, maxAvatarUpload)

	file, header, err := c.Request.FormFile("avatar")
	if err != nil {
		httpx.FailWith(c, apperr.Validation(
			"Rasm yuborilmadi. \"avatar\" maydonida fayl yuboring."))
		return
	}
	defer func() { _ = file.Close() }()

	data, err := io.ReadAll(io.LimitReader(file, maxAvatarUpload))
	if err != nil {
		httpx.FailWith(c, apperr.Validation("Rasmni o‘qib bo‘lmadi."))
		return
	}

	url, err := h.svc.SaveAvatar(c.Request.Context(), userID,
		header.Header.Get("Content-Type"), data)
	if err != nil {
		httpx.FailWith(c, err)
		return
	}

	httpx.OK(c, http.StatusOK, avatarResponse{AvatarURL: url})
}

// currentUser reads the authenticated identity that middleware placed in the context.
func currentUser(c *gin.Context) (uuid.UUID, bool) {
	raw, ok := ctxutil.UserID(c.Request.Context())
	if !ok {
		httpx.FailWith(c, apperr.Unauthenticated("Authentication required."))
		return uuid.Nil, false
	}
	id, err := uuid.Parse(raw)
	if err != nil {
		httpx.FailWith(c, apperr.Unauthenticated("Authentication required."))
		return uuid.Nil, false
	}
	return id, true
}
