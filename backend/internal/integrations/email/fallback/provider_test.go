package fallback

import (
	"context"
	"errors"
	"log/slog"
	"os"
	"testing"

	"github.com/samandar-hodiev/voca/backend/internal/auth"
)

func discardLogger() *slog.Logger {
	return slog.New(slog.NewTextHandler(os.NewFile(0, os.DevNull), nil))
}

type recorder struct {
	name string
	sent []auth.EmailMessage
	err  error
}

func (r *recorder) Name() string { return r.name }

func (r *recorder) Send(_ context.Context, msg auth.EmailMessage) error {
	if r.err != nil {
		return r.err
	}
	r.sent = append(r.sent, msg)
	return nil
}

// The guard that matters: in production a provider that will not send is a real failure.
// Quietly writing a customer's code to a server disk and reporting success would be worse
// than an error.
func TestNewRefusesProduction(t *testing.T) {
	_, err := New(&recorder{}, &recorder{}, true, discardLogger())
	if err == nil {
		t.Fatal("expected the fallback to refuse to run in production")
	}
}

func TestSendUsesTheRealProviderWhenItWorks(t *testing.T) {
	primary := &recorder{name: "resend"}
	local := &recorder{name: "outbox"}
	p, err := New(primary, local, false, discardLogger())
	if err != nil {
		t.Fatalf("New: %v", err)
	}

	msg := auth.EmailMessage{To: "a@b.com", Template: auth.TemplateSignupCode}
	if err := p.Send(context.Background(), msg); err != nil {
		t.Fatalf("Send: %v", err)
	}

	if len(primary.sent) != 1 {
		t.Errorf("the real provider got %d messages, want 1", len(primary.sent))
	}
	if len(local.sent) != 0 {
		t.Errorf("the outbox got %d messages, want none", len(local.sent))
	}
}

// A refused recipient is the case this exists for: the message lands in the outbox and the
// caller succeeds, so sign-up continues instead of stopping on a configuration limit.
func TestSendFallsBackWhenTheRealProviderRefuses(t *testing.T) {
	primary := &recorder{name: "resend", err: errors.New("recipient not allowed")}
	local := &recorder{name: "outbox"}
	p, _ := New(primary, local, false, discardLogger())

	msg := auth.EmailMessage{To: "stranger@example.com", Template: auth.TemplateSignupCode}
	if err := p.Send(context.Background(), msg); err != nil {
		t.Fatalf("a refused recipient should still succeed locally, got %v", err)
	}

	if len(local.sent) != 1 {
		t.Fatalf("the outbox got %d messages, want 1", len(local.sent))
	}
	if local.sent[0].To != "stranger@example.com" {
		t.Errorf("recipient = %q, want the address that was typed", local.sent[0].To)
	}
}

// If even the local write fails there is nothing left to try, and the caller has to know.
func TestSendFailsWhenBothFail(t *testing.T) {
	primary := &recorder{name: "resend", err: errors.New("refused")}
	local := &recorder{name: "outbox", err: errors.New("disk full")}
	p, _ := New(primary, local, false, discardLogger())

	err := p.Send(context.Background(), auth.EmailMessage{To: "a@b.com"})
	if err == nil {
		t.Fatal("expected an error when the outbox fails too")
	}
}

// The name says both, so a startup log cannot be mistaken for a fully working provider.
func TestNameMentionsBoth(t *testing.T) {
	p, _ := New(&recorder{name: "resend"}, &recorder{name: "outbox"}, false, discardLogger())
	if got := p.Name(); got != "resend+outbox" {
		t.Errorf("Name() = %q, want it to name both", got)
	}
}
