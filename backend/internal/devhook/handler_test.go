package devhook

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
)

func newTestServer(t *testing.T, secret string, notifier Notifier) *gin.Engine {
	t.Helper()
	gin.SetMode(gin.TestMode)

	log := discardLogger()
	handler := NewHandler(NewService(notifier, log), secret, log)

	r := gin.New()
	RegisterRoutes(r.Group("/api/v1"), handler)
	return r
}

func postWebhook(t *testing.T, r *gin.Engine, event, signature, body string) *httptest.ResponseRecorder {
	t.Helper()
	req := httptest.NewRequest(http.MethodPost, "/api/v1/webhooks/github", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	if event != "" {
		req.Header.Set("X-GitHub-Event", event)
	}
	if signature != "" {
		req.Header.Set("X-Hub-Signature-256", signature)
	}
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	return w
}

func TestWebhook_ValidPushIsAcceptedAndNotified(t *testing.T) {
	notifier := &fakeNotifier{}
	r := newTestServer(t, testSecret, notifier)

	sig := ComputeSignature(testSecret, []byte(validPushPayload))
	w := postWebhook(t, r, "push", sig, validPushPayload)

	if w.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200. body: %s", w.Code, w.Body.String())
	}
	if len(notifier.calls) != 1 {
		t.Fatalf("notifier called %d times, want 1", len(notifier.calls))
	}

	var resp struct {
		Data struct {
			Status     string `json:"status"`
			Repository string `json:"repository"`
			Branch     string `json:"branch"`
			Commits    int    `json:"commits"`
			Delivered  bool   `json:"delivered"`
		} `json:"data"`
	}
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("response is not the standard envelope: %v", err)
	}
	if resp.Data.Status != "processed" || !resp.Data.Delivered {
		t.Errorf("unexpected response: %+v", resp.Data)
	}
	if resp.Data.Repository != "samandar-hodiev/voca" || resp.Data.Branch != "main" || resp.Data.Commits != 2 {
		t.Errorf("unexpected parsed values: %+v", resp.Data)
	}
}

func TestWebhook_InvalidSignatureIsRejected(t *testing.T) {
	notifier := &fakeNotifier{}
	r := newTestServer(t, testSecret, notifier)

	w := postWebhook(t, r, "push", "sha256=deadbeef", validPushPayload)

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d, want 401", w.Code)
	}
	if len(notifier.calls) != 0 {
		t.Fatal("an unverified payload must never reach the notifier")
	}
}

func TestWebhook_MissingSignatureIsRejected(t *testing.T) {
	notifier := &fakeNotifier{}
	r := newTestServer(t, testSecret, notifier)

	w := postWebhook(t, r, "push", "", validPushPayload)

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d, want 401", w.Code)
	}
	if len(notifier.calls) != 0 {
		t.Fatal("a request without a signature must never reach the notifier")
	}
}

// Without a configured secret the endpoint must fail closed.
func TestWebhook_UnconfiguredSecretRejectsEverything(t *testing.T) {
	notifier := &fakeNotifier{}
	r := newTestServer(t, "", notifier)

	w := postWebhook(t, r, "push", ComputeSignature("", []byte(validPushPayload)), validPushPayload)

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d, want 401 when no secret is configured", w.Code)
	}
}

func TestWebhook_MalformedPayloadWithValidSignature(t *testing.T) {
	notifier := &fakeNotifier{}
	r := newTestServer(t, testSecret, notifier)

	body := `{"ref": "refs/heads/main"` // truncated JSON
	w := postWebhook(t, r, "push", ComputeSignature(testSecret, []byte(body)), body)

	if w.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want 400", w.Code)
	}
	if len(notifier.calls) != 0 {
		t.Fatal("a malformed payload must not produce a notification")
	}
}

func TestWebhook_PingIsAnswered(t *testing.T) {
	notifier := &fakeNotifier{}
	r := newTestServer(t, testSecret, notifier)

	body := `{"zen":"Non-blocking is better than blocking."}`
	w := postWebhook(t, r, "ping", ComputeSignature(testSecret, []byte(body)), body)

	if w.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200 for ping", w.Code)
	}
	if len(notifier.calls) != 0 {
		t.Fatal("a ping must not send a Telegram notification")
	}
}

func TestWebhook_UnknownEventIsIgnoredWith200(t *testing.T) {
	notifier := &fakeNotifier{}
	r := newTestServer(t, testSecret, notifier)

	body := `{"action":"opened"}`
	w := postWebhook(t, r, "issues", ComputeSignature(testSecret, []byte(body)), body)

	// 200 so GitHub does not retry an event we simply do not handle.
	if w.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200", w.Code)
	}
	if len(notifier.calls) != 0 {
		t.Fatal("an unhandled event must not notify")
	}
}

// A failing transport must not fail the webhook: GitHub retrying cannot fix a bad token.
func TestWebhook_DeliveryFailureStillReturns200(t *testing.T) {
	notifier := &fakeNotifier{err: errTransport}
	r := newTestServer(t, testSecret, notifier)

	sig := ComputeSignature(testSecret, []byte(validPushPayload))
	w := postWebhook(t, r, "push", sig, validPushPayload)

	if w.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200", w.Code)
	}
	if !strings.Contains(w.Body.String(), `"delivered":false`) {
		t.Errorf("response must report delivered=false, got %s", w.Body.String())
	}
}
