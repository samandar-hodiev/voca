package outbox

import (
	"context"
	"io/fs"
	"log/slog"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/samandar-hodiev/voca/backend/internal/auth"
)

func discardLogger() *slog.Logger {
	return slog.New(slog.NewTextHandler(os.NewFile(0, os.DevNull), nil))
}

// The whole point of the guard: a production process must not be able to write
// verification codes to disk, however the environment is configured.
func TestNewRefusesProduction(t *testing.T) {
	if _, err := New(t.TempDir(), true, discardLogger()); err == nil {
		t.Fatal("expected the outbox provider to refuse to start in production")
	}
}

func TestNewRequiresDirectory(t *testing.T) {
	if _, err := New("  ", false, discardLogger()); err == nil {
		t.Fatal("expected an empty directory to be rejected")
	}
}

func TestSendWritesReadableMessage(t *testing.T) {
	dir := filepath.Join(t.TempDir(), "mail")
	p, err := New(dir, false, discardLogger())
	if err != nil {
		t.Fatalf("New: %v", err)
	}

	err = p.Send(context.Background(), auth.EmailMessage{
		To:       "someone@example.com",
		Template: auth.TemplateSignupCode,
		Params:   map[string]string{"code": "123456"},
	})
	if err != nil {
		t.Fatalf("Send: %v", err)
	}

	entries, err := os.ReadDir(dir)
	if err != nil {
		t.Fatalf("ReadDir: %v", err)
	}
	if len(entries) != 1 {
		t.Fatalf("expected exactly one message, got %d", len(entries))
	}

	path := filepath.Join(dir, entries[0].Name())
	body, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("ReadFile: %v", err)
	}
	text := string(body)
	if !strings.Contains(text, "123456") {
		t.Error("the developer must be able to read the code out of the file")
	}
	if !strings.Contains(text, "someone@example.com") {
		t.Error("the recipient should appear in the rendered message")
	}

	// A code on disk is only acceptable while nobody else on the machine can read it.
	info, err := os.Stat(path)
	if err != nil {
		t.Fatalf("Stat: %v", err)
	}
	if perm := info.Mode().Perm(); perm != fs.FileMode(0o600) {
		t.Errorf("message permissions = %v, want 0600", perm)
	}
	dirInfo, err := os.Stat(dir)
	if err != nil {
		t.Fatalf("Stat dir: %v", err)
	}
	if perm := dirInfo.Mode().Perm(); perm != fs.FileMode(0o700) {
		t.Errorf("directory permissions = %v, want 0700", perm)
	}
}

// Two messages in the same second must not overwrite each other, otherwise a resend
// silently replaces the code a developer is reading.
func TestSendDoesNotOverwriteRapidMessages(t *testing.T) {
	dir := t.TempDir()
	p, err := New(dir, false, discardLogger())
	if err != nil {
		t.Fatalf("New: %v", err)
	}
	for range 3 {
		if err := p.Send(context.Background(), auth.EmailMessage{
			To:       "a@example.com",
			Template: auth.TemplatePasswordResetCode,
			Params:   map[string]string{"code": "000000"},
		}); err != nil {
			t.Fatalf("Send: %v", err)
		}
	}
	entries, _ := os.ReadDir(dir)
	if len(entries) != 3 {
		t.Fatalf("expected 3 distinct files, got %d", len(entries))
	}
}
