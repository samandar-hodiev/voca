package telegramdev

import (
	"context"
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

// The guard that matters most: a customer's verification code must never be posted to a
// chat the developer owns.
func TestNewRefusesProduction(t *testing.T) {
	_, err := New(Config{BotToken: "t", ChatID: "1"}, true, discardLogger())
	if err == nil {
		t.Fatal("expected the development provider to refuse to start in production")
	}
}

func TestNewRequiresCredentials(t *testing.T) {
	if _, err := New(Config{ChatID: "1"}, false, discardLogger()); err == nil {
		t.Error("expected a missing bot token to be rejected")
	}
	if _, err := New(Config{BotToken: "t"}, false, discardLogger()); err == nil {
		t.Error("expected a missing chat id to be rejected")
	}
}

func TestSendPostsTheCodeAndTheIntendedRecipient(t *testing.T) {
	var form string
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_ = r.ParseForm()
		form = r.Form.Get("text")
		if got := r.Form.Get("chat_id"); got != "12345" {
			t.Errorf("chat_id = %q, want 12345", got)
		}
		w.WriteHeader(http.StatusOK)
	}))
	defer server.Close()

	p, err := New(Config{
		BotToken: "bot-token", ChatID: "12345", BaseURL: server.URL,
	}, false, discardLogger())
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

	if !strings.Contains(form, "482915") {
		t.Error("the message must carry the code")
	}
	// Stating who it was for is what stops it being mistaken for the reader's own code.
	if !strings.Contains(form, "learner@example.com") {
		t.Error("the message must name the intended recipient")
	}
}

func TestSendFailsWhenTelegramRejects(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusBadRequest)
		_, _ = w.Write([]byte(`{"description":"chat not found"}`))
	}))
	defer server.Close()

	p, _ := New(Config{
		BotToken: "t", ChatID: "1", BaseURL: server.URL,
	}, false, discardLogger())

	err := p.Send(context.Background(), auth.EmailMessage{
		To: "a@b.com", Template: auth.TemplateSignupCode,
	})
	if err == nil {
		t.Fatal("expected a rejected message to return an error")
	}
}

func TestSendRejectsMissingRecipient(t *testing.T) {
	p, _ := New(Config{BotToken: "t", ChatID: "1"}, false, discardLogger())
	if err := p.Send(context.Background(), auth.EmailMessage{}); err == nil {
		t.Fatal("expected a message with no recipient to be rejected")
	}
}
