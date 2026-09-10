// Package log is the development email provider.
//
// It writes a line saying that a message WOULD have been sent, so local development and
// CI need no email credentials.
//
// It deliberately does NOT log the verification code. A code in a log file is a code an
// attacker with log access can use, and development logs leak into terminals, screen
// shares and bug reports. The code is retrieved during development from the database or
// from a real inbox, never from here (ARCHITECTURE.md 18.4).
package log

import (
	"context"
	"log/slog"

	"github.com/samandar-hodiev/voca/backend/internal/auth"
)

type Provider struct {
	log *slog.Logger
}

func New(logger *slog.Logger) *Provider { return &Provider{log: logger} }

func (p *Provider) Name() string { return "log" }

func (p *Provider) Send(_ context.Context, msg auth.EmailMessage) error {
	p.log.Info("email_not_sent_development_provider",
		slog.String("template", string(msg.Template)),
		// The recipient is logged because it is needed to debug a flow; the code never is.
		slog.String("to", msg.To),
		slog.Int("params", len(msg.Params)),
	)
	return nil
}
