// progress: HTTP handlers. THIN LAYER — no business logic.
//
// Responsibility: bind and validate the request DTO, read the authenticated user from
// context, call exactly ONE service method, map the domain result or error to HTTP.
//
// MUST NOT contain: SQL, provider calls, or business branching such as "if user is premium".
//
// See ARCHITECTURE.md 14, 5.3 (handler rules), 19 (error mapping), 31.2 (dependency rules).

package progress

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

// Summary answers GET /api/v1/progress/summary for the signed-in learner.
func (h *Handler) Summary(c *gin.Context) {
	userID, ok := currentUser(c)
	if !ok {
		return
	}

	summary, err := h.svc.Summary(c.Request.Context(), userID)
	if err != nil {
		httpx.FailWith(c, err)
		return
	}
	httpx.OK(c, http.StatusOK, toSummaryResponse(summary))
}

// currentUser reads the authenticated user the middleware put in the context. Whose
// progress is being read is never taken from the request.
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
