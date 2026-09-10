// Package resend delivers email through the Resend HTTP API.
//
// Why an HTTP provider exists alongside the SMTP one. Many networks, including a lot of
// consumer ISPs, block outbound ports 587 and 465 to keep spam off their lines. On such a
// connection SMTP cannot work at all, however correct the credentials are: the TCP
// connection simply never completes. A transactional mail API speaks HTTPS on 443, which
// is the one port that is always open, so it works from anywhere the app already reaches
// the internet.
//
// The API key is configuration and is never logged. Neither is the code: the body goes
// straight into the request and never into a log line (ARCHITECTURE.md 18.4).
package resend

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/samandar-hodiev/voca/backend/internal/auth"
	"github.com/samandar-hodiev/voca/backend/internal/integrations/email/template"
)

const (
	defaultEndpoint = "https://api.resend.com/emails"
	defaultTimeout  = 15 * time.Second
)

// Config is what the provider needs.
type Config struct {
	APIKey string

	// From is the sender. Resend requires either a verified domain or its shared
	// onboarding address; anything else is rejected with a clear message.
	From string

	// FromName is the display name. Optional.
	FromName string

	// Endpoint is overridden by tests. Empty means the real API.
	Endpoint string

	Timeout time.Duration
}

// Provider sends mail over HTTPS.
type Provider struct {
	cfg    Config
	client *http.Client
	log    *slog.Logger
}

// New validates the configuration and returns a provider.
func New(cfg Config, logger *slog.Logger) (*Provider, error) {
	if strings.TrimSpace(cfg.APIKey) == "" {
		return nil, errors.New("resend: api key is required")
	}
	if strings.TrimSpace(cfg.From) == "" {
		return nil, errors.New("resend: from address is required")
	}
	if cfg.Endpoint == "" {
		cfg.Endpoint = defaultEndpoint
	}
	if cfg.Timeout <= 0 {
		cfg.Timeout = defaultTimeout
	}
	return &Provider{
		cfg:    cfg,
		client: &http.Client{Timeout: cfg.Timeout},
		log:    logger,
	}, nil
}

func (p *Provider) Name() string { return "resend" }

type sendRequest struct {
	From    string   `json:"from"`
	To      []string `json:"to"`
	Subject string   `json:"subject"`
	Text    string   `json:"text"`
}

// Send delivers one message.
func (p *Provider) Send(ctx context.Context, msg auth.EmailMessage) error {
	if strings.TrimSpace(msg.To) == "" {
		return errors.New("resend: recipient is required")
	}

	from := p.cfg.From
	if p.cfg.FromName != "" {
		from = fmt.Sprintf("%s <%s>", p.cfg.FromName, p.cfg.From)
	}

	body, err := json.Marshal(sendRequest{
		From:    from,
		To:      []string{msg.To},
		Subject: template.Subject(msg.Template),
		Text:    template.Body(msg),
	})
	if err != nil {
		return fmt.Errorf("encode message: %w", err)
	}

	req, err := http.NewRequestWithContext(
		ctx, http.MethodPost, p.cfg.Endpoint, bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("build request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+p.cfg.APIKey)
	req.Header.Set("Content-Type", "application/json")

	res, err := p.client.Do(req)
	if err != nil {
		p.log.Error("resend_send_failed",
			slog.String("template", string(msg.Template)),
			slog.String("to", msg.To),
			slog.String("error", err.Error()),
		)
		return fmt.Errorf("send message: %w", err)
	}
	defer func() { _ = res.Body.Close() }()

	if res.StatusCode < 200 || res.StatusCode >= 300 {
		// The response body carries the reason a message was rejected, such as an
		// unverified sender. It is logged because it explains a misconfiguration and
		// contains no part of the message.
		reason, _ := io.ReadAll(io.LimitReader(res.Body, 2048))
		p.log.Error("resend_rejected_message",
			slog.Int("status", res.StatusCode),
			slog.String("to", msg.To),
			slog.String("reason", strings.TrimSpace(string(reason))),
		)
		return fmt.Errorf("resend rejected the message: status %d", res.StatusCode)
	}

	p.log.Info("email_sent",
		slog.String("provider", "resend"),
		slog.String("template", string(msg.Template)),
		slog.String("to", msg.To),
	)
	return nil
}
