// HTTP handler for GitHub webhooks. THIN LAYER — no business logic.
//
// Responsibility: read the raw body safely, verify the signature, dispatch by event type,
// and map the outcome to a status code. Everything else belongs to the service
// (ARCHITECTURE.md 5.3).
package devhook

import (
	"io"
	"log/slog"
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/samandar-hodiev/voca/backend/internal/shared/httpx"
)

// maxWebhookBody caps the request body. GitHub payloads are well under this; the limit
// exists so an oversized or hostile body is rejected without being buffered
// (ARCHITECTURE.md 18.2).
const maxWebhookBody = 1 << 20 // 1 MiB

// Handler serves the GitHub webhook endpoint.
type Handler struct {
	svc    *Service
	secret string
	log    *slog.Logger
}

// NewHandler builds the handler. The secret comes from configuration, never a literal.
func NewHandler(svc *Service, secret string, log *slog.Logger) *Handler {
	return &Handler{svc: svc, secret: secret, log: log}
}

// GitHubWebhook handles POST /api/v1/webhooks/github.
func (h *Handler) GitHubWebhook(c *gin.Context) {
	body, err := io.ReadAll(io.LimitReader(c.Request.Body, maxWebhookBody))
	if err != nil {
		httpx.Fail(c, http.StatusBadRequest, "INVALID_BODY", "Could not read request body.")
		return
	}

	// Signature is verified BEFORE the body is parsed: never spend work on, or trust the
	// shape of, an unverified payload.
	signature := c.GetHeader("X-Hub-Signature-256")
	if !VerifySignature(h.secret, body, signature) {
		// The reason is logged, not returned: telling a caller WHY verification failed
		// helps them forge a valid request.
		h.log.Warn("devhook_invalid_signature",
			slog.String("request_id", httpx.RequestID(c)),
			slog.Bool("secret_configured", h.secret != ""),
			slog.Bool("signature_present", signature != ""),
		)
		httpx.Fail(c, http.StatusUnauthorized, "INVALID_SIGNATURE", "Signature verification failed.")
		return
	}

	switch event := c.GetHeader("X-GitHub-Event"); event {
	case "ping":
		// GitHub sends this once when the webhook is created.
		httpx.OK(c, http.StatusOK, gin.H{"status": "pong"})

	case "push":
		ev, err := ParsePushEvent(body)
		if err != nil {
			h.log.Warn("devhook_malformed_push",
				slog.String("request_id", httpx.RequestID(c)),
				slog.String("error", err.Error()),
			)
			httpx.Fail(c, http.StatusBadRequest, "INVALID_PAYLOAD", "Malformed push payload.")
			return
		}

		// Delivery failure does not fail the webhook: GitHub would retry the delivery,
		// which cannot fix a broken Telegram token. The outcome is reported in the body.
		delivered := true
		if err := h.svc.HandlePush(c.Request.Context(), ev); err != nil {
			delivered = false
			h.log.Error("devhook_notify_failed",
				slog.String("request_id", httpx.RequestID(c)),
				slog.String("error", err.Error()),
			)
		}
		httpx.OK(c, http.StatusOK, gin.H{
			"status":     "processed",
			"event":      "push",
			"repository": ev.Repository,
			"branch":     ev.Branch,
			"commits":    ev.CommitCount,
			"delivered":  delivered,
		})

	default:
		// Unhandled events get 200 so GitHub does not retry them forever.
		httpx.OK(c, http.StatusOK, gin.H{"status": "ignored", "event": event})
	}
}
