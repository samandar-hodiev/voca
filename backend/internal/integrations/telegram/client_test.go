package telegram

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/samandar-hodiev/voca/backend/internal/devhook"
)

// Tests point the client at a local test server. No real Telegram API call is ever made
// (ARCHITECTURE.md 22.1).
func newTestClient(t *testing.T, handler http.HandlerFunc) (*Client, *httptest.Server) {
	t.Helper()
	srv := httptest.NewServer(handler)
	t.Cleanup(srv.Close)

	c := New("secret-bot-token", "-1001234567890")
	c.baseURL = srv.URL
	return c, srv
}

func sampleNotification() devhook.Notification {
	return devhook.Notification{
		Title: "🚀 New push to Voca",
		Fields: []devhook.Field{
			{Label: "Repository", Value: "samandar-hodiev/voca"},
			{Label: "Branch", Value: "main"},
			{Label: "Author", Value: "samandar-hodiev"},
			{Label: "Commits", Value: "2"},
			{Label: "Latest", Value: "backend ishga tushirildi"},
		},
		Link: "https://github.com/samandar-hodiev/voca/commit/abc123",
	}
}

func TestNotify_SendsExpectedRequest(t *testing.T) {
	var gotPath string
	var gotBody map[string]any

	client, _ := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
		gotPath = r.URL.Path
		raw, _ := io.ReadAll(r.Body)
		_ = json.Unmarshal(raw, &gotBody)
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"ok":true}`))
	})

	if err := client.Notify(context.Background(), sampleNotification()); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if gotPath != "/botsecret-bot-token/sendMessage" {
		t.Errorf("path = %q", gotPath)
	}
	if gotBody["chat_id"] != "-1001234567890" {
		t.Errorf("chat_id = %v", gotBody["chat_id"])
	}

	text, _ := gotBody["text"].(string)
	for _, want := range []string{
		"🚀 New push to Voca",
		"Repository: samandar-hodiev/voca",
		"Branch: main",
		"Author: samandar-hodiev",
		"Commits: 2",
		"Latest: backend ishga tushirildi",
		"https://github.com/samandar-hodiev/voca/commit/abc123",
	} {
		if !strings.Contains(text, want) {
			t.Errorf("message text is missing %q\ngot:\n%s", want, text)
		}
	}

	// parse_mode must stay absent: commit messages are attacker-influenced text, and
	// enabling HTML or Markdown would require escaping every value forever.
	if _, present := gotBody["parse_mode"]; present {
		t.Error("parse_mode must not be sent; messages are plain text on purpose")
	}
}

func TestNotify_ApiRejectionIsReported(t *testing.T) {
	client, _ := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusBadRequest)
		_, _ = w.Write([]byte(`{"ok":false,"error_code":400,"description":"chat not found"}`))
	})

	err := client.Notify(context.Background(), sampleNotification())
	if err == nil {
		t.Fatal("an API rejection must be returned as an error")
	}
	if !strings.Contains(err.Error(), "chat not found") {
		t.Errorf("error should carry the API description, got: %v", err)
	}
}

// The bot token sits in the request URL, so transport errors must be scrubbed before
// they can reach a log (ARCHITECTURE.md 18.4).
func TestNotify_TokenNeverAppearsInError(t *testing.T) {
	const token = "super-secret-token-value"

	client := New(token, "123")
	client.baseURL = "http://127.0.0.1:1" // guaranteed connection refused

	err := client.Notify(context.Background(), sampleNotification())
	if err == nil {
		t.Fatal("expected a transport error")
	}
	if strings.Contains(err.Error(), token) {
		t.Fatalf("the bot token leaked into an error message: %v", err)
	}
}
