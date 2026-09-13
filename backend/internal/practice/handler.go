// practice: HTTP handlers. THIN LAYER — no business logic.
//
// See ARCHITECTURE.md 13, 5.3 (handler rules), 19 (error mapping).

package practice

import (
	"log/slog"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/samandar-hodiev/voca/backend/internal/shared/ctxutil"
	"github.com/samandar-hodiev/voca/backend/internal/shared/httpx"
)

type Handler struct {
	svc *Service
	log *slog.Logger
}

func NewHandler(svc *Service, log *slog.Logger) *Handler {
	return &Handler{svc: svc, log: log}
}

// Current answers POST /api/v1/practice/sessions and GET /api/v1/practice/sessions/current.
//
// One method for both because there is only ever one answer: the set this learner owes.
// Creating it is idempotent, which is what lets the app ask on every open without
// worrying about spawning sessions.
func (h *Handler) Current(c *gin.Context) {
	userID, ok := currentUser(c)
	if !ok {
		return
	}

	session, err := h.svc.Current(c.Request.Context(), userID)
	if err != nil {
		httpx.FailWith(c, err)
		return
	}
	httpx.OK(c, http.StatusOK, toSessionResponse(session, h.svc.PassScore()))
}

// Week answers GET /api/v1/practice/week.
func (h *Handler) Week(c *gin.Context) {
	userID, ok := currentUser(c)
	if !ok {
		return
	}

	days, err := h.svc.Week(c.Request.Context(), userID)
	if err != nil {
		httpx.FailWith(c, err)
		return
	}
	httpx.OK(c, http.StatusOK, gin.H{
		"days":       toDayResponses(days),
		"pass_score": h.svc.PassScore(),
	})
}

// Complete answers POST /api/v1/practice/sessions/{id}/complete.
func (h *Handler) Complete(c *gin.Context) {
	userID, ok := currentUser(c)
	if !ok {
		return
	}

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		httpx.Fail(c, http.StatusNotFound, "NOT_FOUND", "Bunday mashq topilmadi.")
		return
	}

	session, err := h.svc.Complete(c.Request.Context(), userID, id)
	if err != nil {
		httpx.FailWith(c, err)
		return
	}
	httpx.OK(c, http.StatusOK, toSessionResponse(session, h.svc.PassScore()))
}

func currentUser(c *gin.Context) (uuid.UUID, bool) {
	raw, ok := ctxutil.UserID(c.Request.Context())
	if !ok {
		httpx.Fail(c, http.StatusUnauthorized, "UNAUTHENTICATED", "Authentication required.")
		return uuid.Nil, false
	}
	id, err := uuid.Parse(raw)
	if err != nil {
		httpx.Fail(c, http.StatusUnauthorized, "UNAUTHENTICATED", "Authentication required.")
		return uuid.Nil, false
	}
	return id, true
}
