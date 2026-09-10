package resend

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"

	"github.com/samandar-hodiev/voca/backend/internal/auth"
)

func discardLogger() *slog.Logger {
	return slog.New(slog.NewTextHandler(os.NewFile(0, os.DevNull), nil))
}

func TestNewRejectsIncompleteConfig(t *testing.T) {
	if _, err := New(Config{From: "a@b.com"}, discardLogger()); err == nil {
		t.Error("expected a missing api key to be rejected")
	}
	if _, err := New(Config{APIKey: "re_x"}, discardLogger()); err == nil {
		t.Error("expected a missing sender to be rejected")
	}
}

func TestSendPostsTheMessage(t *testing.T) {
	var got sendRequest
	var authHeader string

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader = r.Header.Get("Authorization")
		_ = json.NewDecoder(r.Body).Decode(&got)
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"id":"abc"}`))
	}))
	defer server.Close()

	p, err := New(Config{
		APIKey: "re_test", From: "voca@example.com", FromName: "Voca",
		Endpoint: server.URL,
	}, discardLogger())
	if err != nil {
		t.Fatalf("New: %v", err)
	}

	err = p.Send(context.Background(), auth.EmailMessage{
		To:       "learner@example.com",
		Template: auth.TemplateSignupCode,
		Params:   map[string]string{"code": "482915"},
	})
	if err != nil {
		t.Fatalf("Send: %v", err)
	}

	if authHeader != "Bearer re_test" {
		t.Errorf("Authorization = %q, want a bearer token", authHeader)
	}
	if len(got.To) != 1 || got.To[0] != "learner@example.com" {
		t.Errorf("To = %v", got.To)
	}
	if !strings.Contains(got.From, "voca@example.com") {
		t.Errorf("From = %q, want the configured sender", got.From)
	}
	if got.Subject == "" {
		t.Error("subject must not be empty")
	}
	if !strings.Contains(got.Text, "482915") {
		t.Error("the body must carry the code")
	}
}

// A rejection has to surface as an error. Reporting success for a message the API refused
// would leave somebody waiting for a code that is never coming.
func TestSendFailsOnRejection(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusUnprocessableEntity)
		_, _ = w.Write([]byte(`{"message":"sender not verified"}`))
	}))
	defer server.Close()

	p, _ := New(Config{
		APIKey: "re_test", From: "voca@example.com", Endpoint: server.URL,
	}, discardLogger())

	err := p.Send(context.Background(), auth.EmailMessage{
		To: "learner@example.com", Template: auth.TemplateSignupCode,
	})
	if err == nil {
		t.Fatal("expected a rejected message to return an error")
	}
}

func TestSendRejectsMissingRecipient(t *testing.T) {
	p, _ := New(Config{APIKey: "re_test", From: "a@b.com"}, discardLogger())
	if err := p.Send(context.Background(), auth.EmailMessage{}); err == nil {
		t.Fatal("expected a message with no recipient to be rejected")
	}
}
