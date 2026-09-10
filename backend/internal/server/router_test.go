package server

import (
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"

	"github.com/samandar-hodiev/voca/backend/internal/devhook"
	"github.com/samandar-hodiev/voca/backend/internal/middleware"
)

func newTestRouter(t *testing.T) *gin.Engine {
	t.Helper()
	gin.SetMode(gin.TestMode)

	log := slog.New(slog.NewTextHandler(io.Discard, nil))
	svc := devhook.NewService(devhook.NewLogNotifier(log), log)

	return NewRouter(Dependencies{
		Logger:         log,
		CORS:           middleware.CORSConfig{},
		DevhookHandler: devhook.NewHandler(svc, "test-secret", log),
	})
}

func get(r *gin.Engine, path string) *httptest.ResponseRecorder {
	w := httptest.NewRecorder()
	r.ServeHTTP(w, httptest.NewRequest(http.MethodGet, path, nil))
	return w
}

func TestHealth_ReturnsOK(t *testing.T) {
	w := get(newTestRouter(t), "/health")

	if w.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200", w.Code)
	}

	var resp struct {
		Data struct {
			Status string `json:"status"`
		} `json:"data"`
	}
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("health must use the standard envelope: %v", err)
	}
	if resp.Data.Status != "ok" {
		t.Errorf("status = %q, want ok", resp.Data.Status)
	}
}

// /healthz is the platform-conventional alias; both must report the same state.
//
// Only the data payload is compared: meta carries a per-request correlation ID, so two
// responses are expected to differ there.
func TestHealthz_MatchesHealth(t *testing.T) {
	r := newTestRouter(t)

	status := func(path string) (int, string) {
		w := get(r, path)
		var resp struct {
			Data struct {
				Status string `json:"status"`
			} `json:"data"`
		}
		if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
			t.Fatalf("%s: %v", path, err)
		}
		return w.Code, resp.Data.Status
	}

	aCode, aStatus := status("/health")
	bCode, bStatus := status("/healthz")

	if aCode != bCode || aStatus != bStatus {
		t.Errorf("/healthz must match /health, got %d %q vs %d %q",
			aCode, aStatus, bCode, bStatus)
	}
}

// Liveness must stay cheap and must not require a credential.
func TestHealth_NeedsNoAuthentication(t *testing.T) {
	if get(newTestRouter(t), "/health").Code != http.StatusOK {
		t.Error("health must answer without any Authorization header")
	}
}

func TestEveryResponseCarriesARequestID(t *testing.T) {
	w := get(newTestRouter(t), "/health")

	if w.Header().Get("X-Request-ID") == "" {
		t.Error("X-Request-ID must be present so a user report maps to a log line")
	}
}

func TestUnknownRouteIs404(t *testing.T) {
	if got := get(newTestRouter(t), "/api/v1/does-not-exist").Code; got != http.StatusNotFound {
		t.Errorf("status = %d, want 404", got)
	}
}

func TestWebhookRouteIsMounted(t *testing.T) {
	r := newTestRouter(t)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, httptest.NewRequest(http.MethodPost, "/api/v1/webhooks/github", nil))

	// 401 rather than 404 proves the route exists and signature verification runs.
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status = %d, want 401 (route mounted, signature rejected)", w.Code)
	}
}
