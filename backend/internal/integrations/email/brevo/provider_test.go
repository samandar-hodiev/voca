package brevo

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
	if _, err := New(Config{APIKey: "k"}, discardLogger()); err == nil {
		t.Error("expected a missing sender to be rejected")
	}
}

// The point of the whole flow: the code goes to the address the person typed, not to
// anywhere belonging to the developer.
func TestSendAddressesTheMessageToTheRecipient(t *testing.T) {
	var got sendRequest
	var apiKey string

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		apiKey = r.Header.Get("api-key")
		_ = json.NewDecoder(r.Body).Decode(&got)
		w.WriteHeader(http.StatusCreated)
		_, _ = w.Write([]byte(`{"messageId":"<abc@brevo>"}`))
	}))
	defer server.Close()

	p, err := New(Config{
		APIKey: "brevo-key", From: "voca@example.com", FromName: "Voca",
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

	if apiKey != "brevo-key" {
		t.Errorf("api-key header = %q", apiKey)
	}
	if len(got.To) != 1 || got.To[0].Email != "learner@example.com" {
		t.Fatalf("To = %+v, want the address the person typed", got.To)
	}
	if got.Sender.Email != "voca@example.com" {
		t.Errorf("Sender = %q", got.Sender.Email)
	}
	if got.Subject == "" {
		t.Error("subject must not be empty")
	}
	if !strings.Contains(got.TextContent, "482915") {
		t.Error("the body must carry the code")
	}
}

// Two people signing up must each receive their own code at their own address.
func TestSendKeepsRecipientsSeparate(t *testing.T) {
	var seen []string
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var req sendRequest
		_ = json.NewDecoder(r.Body).Decode(&req)
		seen = append(seen, req.To[0].Email+":"+req.TextContent)
		w.WriteHeader(http.StatusCreated)
	}))
	defer server.Close()

	p, _ := New(Config{
		APIKey: "k", From: "voca@example.com", Endpoint: server.URL,
	}, discardLogger())

	_ = p.Send(context.Background(), auth.EmailMessage{
		To: "one@example.com", Template: auth.TemplateSignupCode,
		Params: map[string]string{"code": "111111"},
	})
	_ = p.Send(context.Background(), auth.EmailMessage{
		To: "two@example.com", Template: auth.TemplateSignupCode,
		Params: map[string]string{"code": "222222"},
	})

	if len(seen) != 2 {
		t.Fatalf("expected two messages, got %d", len(seen))
	}
	if !strings.HasPrefix(seen[0], "one@example.com:") || !strings.Contains(seen[0], "111111") {
		t.Error("the first code went to the wrong address")
	}
	if !strings.HasPrefix(seen[1], "two@example.com:") || !strings.Contains(seen[1], "222222") {
		t.Error("the second code went to the wrong address")
	}
	if strings.Contains(seen[0], "222222") || strings.Contains(seen[1], "111111") {
		t.Error("codes leaked between recipients")
	}
}

func TestSendFailsOnRejection(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusUnauthorized)
		_, _ = w.Write([]byte(`{"message":"sender not verified"}`))
	}))
	defer server.Close()

	p, _ := New(Config{APIKey: "k", From: "a@b.com", Endpoint: server.URL}, discardLogger())
	err := p.Send(context.Background(), auth.EmailMessage{
		To: "learner@example.com", Template: auth.TemplateSignupCode,
	})
	if err == nil {
		t.Fatal("expected a rejected message to return an error")
	}
}

func TestSendRejectsMissingRecipient(t *testing.T) {
	p, _ := New(Config{APIKey: "k", From: "a@b.com"}, discardLogger())
	if err := p.Send(context.Background(), auth.EmailMessage{}); err == nil {
		t.Fatal("expected a message with no recipient to be rejected")
	}
}
