// Package smtp delivers email over SMTP.
//
// This is the production and real-inbox path. The log provider proves a message would
// have been sent, the outbox writes it to disk for a developer, and this one actually
// puts it in somebody's inbox.
//
// Two transports, chosen by port, because mail providers disagree about which to offer:
//
//   - Implicit TLS (port 465): the connection is encrypted before a single byte of SMTP
//     is spoken.
//   - STARTTLS (port 587 and everything else): the session opens in the clear and is
//     upgraded. The upgrade is REQUIRED, never best-effort. A server that will not offer
//     STARTTLS gets an error rather than a password and a verification code sent in
//     plain text across the network.
//
// The credentials come from configuration and are never logged. Neither is the code: the
// message body is written straight to the connection and never to a log line
// (ARCHITECTURE.md 18.4).
package smtp

import (
	"context"
	"crypto/tls"
	"errors"
	"fmt"
	"log/slog"
	"mime"
	"net"
	"net/smtp"
	"strings"
	"time"

	"github.com/samandar-hodiev/voca/backend/internal/auth"
	"github.com/samandar-hodiev/voca/backend/internal/integrations/email/template"
)

// Config is what the provider needs to talk to a mail server.
type Config struct {
	Host     string
	Port     int
	Username string
	Password string

	// From is the envelope and header sender. Many providers require it to match the
	// authenticated account, so a mismatch is a common cause of a silent rejection.
	From string

	// FromName is the display name. Optional.
	FromName string

	// Timeout bounds the whole exchange. A mail server that hangs must not hold an HTTP
	// request open.
	Timeout time.Duration
}

const defaultTimeout = 15 * time.Second

// Provider sends mail over SMTP.
type Provider struct {
	cfg Config
	log *slog.Logger
}

// New validates the configuration and returns a provider.
func New(cfg Config, logger *slog.Logger) (*Provider, error) {
	if strings.TrimSpace(cfg.Host) == "" {
		return nil, errors.New("smtp: host is required")
	}
	if cfg.Port <= 0 {
		return nil, errors.New("smtp: port is required")
	}
	if strings.TrimSpace(cfg.From) == "" {
		return nil, errors.New("smtp: from address is required")
	}
	if cfg.Timeout <= 0 {
		cfg.Timeout = defaultTimeout
	}
	return &Provider{cfg: cfg, log: logger}, nil
}

func (p *Provider) Name() string { return "smtp" }

// Send delivers one message.
func (p *Provider) Send(ctx context.Context, msg auth.EmailMessage) error {
	if strings.TrimSpace(msg.To) == "" {
		return errors.New("smtp: recipient is required")
	}

	body := p.render(msg)

	ctx, cancel := context.WithTimeout(ctx, p.cfg.Timeout)
	defer cancel()

	if err := p.deliver(ctx, msg.To, body); err != nil {
		// The error is logged without the body, so a delivery failure is debuggable
		// without the code appearing in a log file.
		p.log.Error("smtp_send_failed",
			slog.String("template", string(msg.Template)),
			slog.String("to", msg.To),
			slog.String("error", err.Error()),
		)
		return err
	}

	p.log.Info("email_sent",
		slog.String("provider", "smtp"),
		slog.String("template", string(msg.Template)),
		slog.String("to", msg.To),
	)
	return nil
}

// deliver opens a connection, authenticates and writes the message.
func (p *Provider) deliver(ctx context.Context, to, body string) error {
	addr := net.JoinHostPort(p.cfg.Host, fmt.Sprint(p.cfg.Port))

	dialer := &net.Dialer{Timeout: p.cfg.Timeout}
	conn, err := dialer.DialContext(ctx, "tcp", addr)
	if err != nil {
		return fmt.Errorf("dial mail server: %w", err)
	}

	// A deadline on the connection covers the rest of the exchange; net/smtp has no
	// context-aware API of its own.
	if deadline, ok := ctx.Deadline(); ok {
		_ = conn.SetDeadline(deadline)
	}

	tlsConfig := &tls.Config{ServerName: p.cfg.Host, MinVersion: tls.VersionTLS12}

	// Port 465 speaks TLS from the first byte. Everything else opens in the clear and
	// must be upgraded.
	if p.cfg.Port == 465 {
		conn = tls.Client(conn, tlsConfig)
	}

	client, err := smtp.NewClient(conn, p.cfg.Host)
	if err != nil {
		_ = conn.Close()
		return fmt.Errorf("start smtp session: %w", err)
	}
	defer func() { _ = client.Close() }()

	if p.cfg.Port != 465 {
		ok, _ := client.Extension("STARTTLS")
		if !ok {
			return errors.New("smtp: server does not offer STARTTLS; refusing to send in plain text")
		}
		if err := client.StartTLS(tlsConfig); err != nil {
			return fmt.Errorf("upgrade to TLS: %w", err)
		}
	}

	if p.cfg.Username != "" {
		auth := smtp.PlainAuth("", p.cfg.Username, p.cfg.Password, p.cfg.Host)
		if err := client.Auth(auth); err != nil {
			return fmt.Errorf("authenticate: %w", err)
		}
	}

	if err := client.Mail(p.cfg.From); err != nil {
		return fmt.Errorf("set sender: %w", err)
	}
	if err := client.Rcpt(to); err != nil {
		return fmt.Errorf("set recipient: %w", err)
	}

	w, err := client.Data()
	if err != nil {
		return fmt.Errorf("open message body: %w", err)
	}
	if _, err := w.Write([]byte(body)); err != nil {
		_ = w.Close()
		return fmt.Errorf("write message body: %w", err)
	}
	if err := w.Close(); err != nil {
		return fmt.Errorf("close message body: %w", err)
	}

	return client.Quit()
}

// render builds the RFC 5322 message.
func (p *Provider) render(msg auth.EmailMessage) string {
	subject := template.Subject(msg.Template)
	body := template.Body(msg)

	from := p.cfg.From
	if p.cfg.FromName != "" {
		// The display name is encoded rather than quoted raw, so a non-ASCII product name
		// does not produce a malformed header.
		from = fmt.Sprintf("%s <%s>", mime.QEncoding.Encode("utf-8", p.cfg.FromName), p.cfg.From)
	}

	// CRLF line endings throughout: SMTP requires them, and a bare newline in a header is
	// how a message gets silently mangled or rejected.
	var b strings.Builder
	b.WriteString("From: " + from + "\r\n")
	b.WriteString("To: " + msg.To + "\r\n")
	b.WriteString("Subject: " + mime.QEncoding.Encode("utf-8", subject) + "\r\n")
	b.WriteString("Date: " + time.Now().Format(time.RFC1123Z) + "\r\n")
	b.WriteString("MIME-Version: 1.0\r\n")
	b.WriteString("Content-Type: text/plain; charset=\"UTF-8\"\r\n")
	b.WriteString("Content-Transfer-Encoding: 8bit\r\n")
	b.WriteString("Auto-Submitted: auto-generated\r\n")
	b.WriteString("\r\n")
	b.WriteString(strings.ReplaceAll(body, "\n", "\r\n"))
	b.WriteString("\r\n")

	return b.String()
}
