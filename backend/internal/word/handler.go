// word: HTTP handlers. THIN LAYER — no business logic.
//
// Responsibility: bind and validate the request DTO, read the authenticated user from
// context, call exactly ONE service method, map the domain result or error to HTTP.
//
// See ARCHITECTURE.md 13.4, 5.3 (handler rules), 19 (error mapping).

package word

import (
	"log/slog"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/samandar-hodiev/voca/backend/internal/shared/httpx"
)

type Handler struct {
	svc *Service
	log *slog.Logger
}

func NewHandler(svc *Service, log *slog.Logger) *Handler {
	return &Handler{svc: svc, log: log}
}

// List answers GET /api/v1/words.
func (h *Handler) List(c *gin.Context) {
	limit, _ := strconv.Atoi(c.Query("limit"))
	offset, _ := strconv.Atoi(c.Query("offset"))

	words, err := h.svc.List(c.Request.Context(), Filter{
		CEFRLevel: c.Query("cefr"),
		Phoneme:   c.Query("phoneme"),
		Search:    c.Query("search"),
		Limit:     limit,
		Offset:    offset,
	})
	if err != nil {
		httpx.FailWith(c, err)
		return
	}
	httpx.OK(c, http.StatusOK, gin.H{"items": toWordResponses(words)})
}

// Get answers GET /api/v1/words/{id}.
func (h *Handler) Get(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		httpx.Fail(c, http.StatusNotFound, "NOT_FOUND", "Bunday so‘z topilmadi.")
		return
	}

	w, err := h.svc.Get(c.Request.Context(), id)
	if err != nil {
		httpx.FailWith(c, err)
		return
	}
	httpx.OK(c, http.StatusOK, toWordResponse(w))
}

// Categories answers GET /api/v1/categories. Empty today, and honestly so: the MVP
// selects words by level, and no category has been authored yet.
func (h *Handler) Categories(c *gin.Context) {
	cats, err := h.svc.Categories(c.Request.Context())
	if err != nil {
		httpx.FailWith(c, err)
		return
	}

	items := make([]categoryResponse, 0, len(cats))
	for _, x := range cats {
		items = append(items, categoryResponse{
			ID: x.ID.String(), Slug: x.Slug, NameKey: x.NameKey,
			Icon: x.Icon, WordCount: x.WordCount,
		})
	}
	httpx.OK(c, http.StatusOK, gin.H{"items": items})
}
