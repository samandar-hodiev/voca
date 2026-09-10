// Package outbox is the development email provider: a local mail catcher.
//
// The log provider proves an email WOULD have been sent but deliberately hides the
// verification code, which makes it impossible to finish a signup by hand on a laptop
// with no mail credentials. This provider closes that gap the way MailHog and Mailpit do:
// it writes the rendered message to a file on disk that the developer opens.
//
// The safety properties that matter are kept:
//
//   - It refuses to run in production. New returns an error there, so a deployment that
//     forgets to configure a real provider fails at startup instead of quietly writing
//     customer verification codes to a server disk.
//   - The code never reaches a log line, a terminal, an HTTP response or a screen share.
//     It lives in one file, in a directory the repository ignores, readable only by the
//     account that runs the server.
//   - The directory is created 0700 and each message 0600.
//
// See ARCHITECTURE.md 18.4 and docs/runbooks/local-development.md.
package outbox

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync/atomic"
	"time"

	"github.com/samandar-hodiev/voca/backend/internal/auth"
	"github.com/samandar-hodiev/voca/backend/internal/integrations/email/template"
)

// Provider writes each outgoing message to its own file.
type Provider struct {
	dir string
	log *slog.Logger

	// seq disambiguates messages written within the same millisecond. A resend arrives
	// immediately after the first send, and without this the second file would overwrite
	// the first — leaving the developer reading a code the server has already replaced.
	seq atomic.Uint64
}

// New creates the provider, creating the outbox directory if it does not exist.
//
// production is passed in rather than read from the environment here so the guard is
// visible at the call site in the composition root.
func New(dir string, production bool, logger *slog.Logger) (*Provider, error) {
	if production {
		return nil, errors.New("outbox email provider must never run in production")
	}
	if strings.TrimSpace(dir) == "" {
		return nil, errors.New("outbox email provider needs a directory")
	}
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return nil, fmt.Errorf("create outbox directory: %w", err)
	}
	return &Provider{dir: dir, log: logger}, nil
}

func (p *Provider) Name() string { return "outbox" }

// Send renders the message and writes it to a timestamped file.
func (p *Provider) Send(_ context.Context, msg auth.EmailMessage) error {
	now := time.Now()
	name := fmt.Sprintf("%s_%03d_%s_%s.txt",
		now.Format("20060102-150405.000"), p.seq.Add(1)%1000, msg.Template, sanitize(msg.To))
	path := filepath.Join(p.dir, name)

	if err := os.WriteFile(path, []byte(render(msg, now)), 0o600); err != nil {
		return fmt.Errorf("write outbox message: %w", err)
	}

	// The path is logged so a developer can find the message. The contents are not.
	p.log.Info("email_written_to_outbox",
		slog.String("template", string(msg.Template)),
		slog.String("to", msg.To),
		slog.String("path", path),
	)
	return nil
}

// render produces the plain-text body a developer reads.
func render(msg auth.EmailMessage, at time.Time) string {
	var b strings.Builder
	fmt.Fprintf(&b, "To:       %s\n", msg.To)
	fmt.Fprintf(&b, "Subject:  %s\n", template.Subject(msg.Template))
	fmt.Fprintf(&b, "Template: %s\n", msg.Template)
	fmt.Fprintf(&b, "Date:     %s\n", at.Format(time.RFC1123))
	b.WriteString(strings.Repeat("-", 56) + "\n\n")
	b.WriteString(template.Body(msg) + "\n\n")
	b.WriteString(strings.Repeat("-", 56) + "\n")
	b.WriteString("Parameters:\n")

	keys := make([]string, 0, len(msg.Params))
	for k := range msg.Params {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	for _, k := range keys {
		fmt.Fprintf(&b, "  %s = %s\n", k, msg.Params[k])
	}
	return b.String()
}

// sanitize keeps a recipient usable as a file name.
func sanitize(s string) string {
	return strings.Map(func(r rune) rune {
		switch {
		case r >= 'a' && r <= 'z', r >= 'A' && r <= 'Z', r >= '0' && r <= '9', r == '.', r == '-':
			return r
		default:
			return '_'
		}
	}, s)
}
