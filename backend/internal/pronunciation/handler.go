// pronunciation: HTTP handlers. THIN LAYER — no business logic.
//
// Responsibility: read the authenticated user from context, pull the multipart fields,
// call exactly ONE service method, map the domain result or error to HTTP.
//
// MUST NOT contain: SQL, provider calls, or business branching such as "if user is premium".
//
// See ARCHITECTURE.md 6, 5.3 (handler rules), 19 (error mapping), 31.2 (dependency rules).

package pronunciation

import (
	"io"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/samandar-hodiev/voca/backend/internal/shared/apperr"
	"github.com/samandar-hodiev/voca/backend/internal/shared/ctxutil"
	"github.com/samandar-hodiev/voca/backend/internal/shared/httpx"
)

// maxUpload bounds what will be READ before it is read. Without it a client can stream an
// arbitrarily large body and the server holds all of it. The service applies the real
// limit afterwards; this is only the outer guard.
const maxUpload = 4 << 20 // 4 MiB

type Handler struct{ svc *Service }

func NewHandler(svc *Service) *Handler { return &Handler{svc: svc} }

// SubmitAttempt accepts a recording and answers with the assessed result.
//
// Multipart rather than JSON because it carries audio: "audio" is the file, and the
// reference text, language and client-measured duration ride alongside it as form fields.
func (h *Handler) SubmitAttempt(c *gin.Context) {
	userID, ok := currentUser(c)
	if !ok {
		return
	}

	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, maxUpload)

	file, header, err := c.Request.FormFile("audio")
	if err != nil {
		httpx.FailWith(c, apperr.Validation(
			"Ovoz yuborilmadi. \"audio\" maydonida fayl yuboring."))
		return
	}
	defer func() { _ = file.Close() }()

	data, err := io.ReadAll(io.LimitReader(file, maxUpload))
	if err != nil {
		httpx.FailWith(c, apperr.Validation("Ovozni o‘qib bo‘lmadi."))
		return
	}

	contentType := header.Header.Get("Content-Type")
	declared, _ := strconv.Atoi(c.Request.FormValue("duration_ms"))

	attempt, err := h.svc.SubmitAttempt(c.Request.Context(), SubmitCommand{
		UserID:             userID,
		Audio:              data,
		ContentType:        contentType,
		ReferenceText:      c.Request.FormValue("reference_text"),
		Language:           c.Request.FormValue("language"),
		DeclaredDurationMS: declared,
	})
	if err != nil {
		httpx.FailWith(c, err)
		return
	}

	httpx.OK(c, http.StatusCreated, toAttemptResponse(attempt))
}

// History returns the learner's own recent attempts.
func (h *Handler) History(c *gin.Context) {
	userID, ok := currentUser(c)
	if !ok {
		return
	}

	limit, _ := strconv.Atoi(c.Query("limit"))

	attempts, err := h.svc.History(c.Request.Context(), userID, limit)
	if err != nil {
		httpx.FailWith(c, err)
		return
	}

	items := make([]attemptResponse, 0, len(attempts))
	for _, a := range attempts {
		items = append(items, toAttemptResponse(a))
	}
	httpx.OK(c, http.StatusOK, gin.H{"items": items})
}

// currentUser reads the authenticated user the middleware put in the context. Which
// account an attempt belongs to is never taken from the request body.
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
