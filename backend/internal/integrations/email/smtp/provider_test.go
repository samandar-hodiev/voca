package smtp

import (
	"log/slog"
	"os"
	"strings"
	"testing"

	"github.com/samandar-hodiev/voca/backend/internal/auth"
)

func discardLogger() *slog.Logger {
	return slog.New(slog.NewTextHandler(os.NewFile(0, os.DevNull), nil))
}

func TestNewRejectsIncompleteConfig(t *testing.T) {
	cases := map[string]Config{
		"no host": {Port: 587, From: "a@b.com"},
		"no port": {Host: "smtp.example.com", From: "a@b.com"},
		"no from": {Host: "smtp.example.com", Port: 587},
	}
	for name, cfg := range cases {
		t.Run(name, func(t *testing.T) {
			if _, err := New(cfg, discardLogger()); err == nil {
				t.Fatal("expected an incomplete configuration to be rejected")
			}
		})
	}
}

func TestNewAppliesDefaultTimeout(t *testing.T) {
	p, err := New(Config{Host: "smtp.example.com", Port: 587, From: "a@b.com"}, discardLogger())
	if err != nil {
		t.Fatalf("New: %v", err)
	}
	if p.cfg.Timeout != defaultTimeout {
		t.Errorf("timeout = %v, want %v", p.cfg.Timeout, defaultTimeout)
	}
}

// The message has to be a valid RFC 5322 message, not just a body with a code in it.
// A bare newline in a header is how a message gets silently mangled.
func TestRenderProducesAWellFormedMessage(t *testing.T) {
	p, err := New(Config{
		Host: "smtp.example.com", Port: 587,
		From: "voca@example.com", FromName: "Voca",
	}, discardLogger())
	if err != nil {
		t.Fatalf("New: %v", err)
	}

	out := p.render(auth.EmailMessage{
		To:       "learner@example.com",
		Template: auth.TemplateSignupCode,
		Params:   map[string]string{"code": "482915"},
	})

	headers, body, found := strings.Cut(out, "\r\n\r\n")
	if !found {
		t.Fatal("message must separate headers from body with a blank line")
	}

	for _, want := range []string{
		"To: learner@example.com",
		"From: ",
		"Subject: ",
		"MIME-Version: 1.0",
		`Content-Type: text/plain; charset="UTF-8"`,
	} {
		if !strings.Contains(headers, want) {
			t.Errorf("headers missing %q", want)
		}
	}

	if strings.Contains(strings.ReplaceAll(headers, "\r\n", ""), "\n") {
		t.Error("a header contains a bare newline")
	}
	if !strings.Contains(headers, "voca@example.com") {
		t.Error("the sender address should appear in the From header")
	}
	if !strings.Contains(body, "482915") {
		t.Error("the body must carry the code")
	}
}

func TestRenderUsesPlainAddressWithoutDisplayName(t *testing.T) {
	p, _ := New(Config{Host: "h", Port: 587, From: "voca@example.com"}, discardLogger())
	out := p.render(auth.EmailMessage{To: "a@b.com", Template: auth.TemplateSignupCode})
	if !strings.Contains(out, "From: voca@example.com\r\n") {
		t.Error("with no display name the From header should be the bare address")
	}
}

func TestSendRejectsMissingRecipient(t *testing.T) {
	p, _ := New(Config{Host: "h", Port: 587, From: "a@b.com"}, discardLogger())
	if err := p.Send(t.Context(), auth.EmailMessage{Template: auth.TemplateSignupCode}); err == nil {
		t.Fatal("expected a message with no recipient to be rejected")
	}
}

// Password reset and signup must not share wording: a person who did not ask for a reset
// needs to be told that nothing has changed.
func TestPasswordResetBodyDiffersFromSignup(t *testing.T) {
	p, _ := New(Config{Host: "h", Port: 587, From: "a@b.com"}, discardLogger())
	signup := p.render(auth.EmailMessage{To: "a@b.com", Template: auth.TemplateSignupCode})
	reset := p.render(auth.EmailMessage{To: "a@b.com", Template: auth.TemplatePasswordResetCode})
	if signup == reset {
		t.Fatal("the two templates render identical messages")
	}
}
