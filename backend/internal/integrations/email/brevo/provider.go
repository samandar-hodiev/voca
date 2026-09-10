// Package brevo delivers email through the Brevo HTTP API.
//
// It exists alongside the Resend adapter because the two have different entry costs, and
// which one is right depends on what the sender owns rather than on anything technical:
//
//   - Resend needs a verified domain before it will send to anybody except the account
//     owner. That is the right shape for a launched product with its own domain.
//   - Brevo will send to any recipient once a single sender ADDRESS is verified, with no
//     domain required. That is the only one of the two that can be used before a domain
//     exists.
//
// Both speak HTTPS on 443, which matters on a network that blocks the SMTP ports, where
// no amount of correct SMTP configuration can connect at all.
//
// The API key is configuration and is never logged. Neither is the code: the body goes
// straight into the request and never into a log line (ARCHITECTURE.md 18.4).
package brevo

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
	defaultEndpoint = "https://api.brevo.com/v3/smtp/email"
	defaultTimeout  = 15 * time.Second
)

// Config is what the provider needs.
type Config struct {
	APIKey string

	// From must be an address verified in the Brevo account. No domain is required.
	From     string
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
		return nil, errors.New("brevo: api key is required")
	}
	if strings.TrimSpace(cfg.From) == "" {
		return nil, errors.New("brevo: sender address is required")
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

func (p *Provider) Name() string { return "brevo" }

type party struct {
	Email string `json:"email"`
	Name  string `json:"name,omitempty"`
}

type sendRequest struct {
	Sender      party   `json:"sender"`
	To          []party `json:"to"`
	Subject     string  `json:"subject"`
	TextContent string  `json:"textContent"`
}

// Send delivers one message to the address it is addressed to.
func (p *Provider) Send(ctx context.Context, msg auth.EmailMessage) error {
	if strings.TrimSpace(msg.To) == "" {
		return errors.New("brevo: recipient is required")
	}

	body, err := json.Marshal(sendRequest{
		Sender:      party{Email: p.cfg.From, Name: p.cfg.FromName},
		To:          []party{{Email: msg.To}},
		Subject:     template.Subject(msg.Template),
		TextContent: template.Body(msg),
	})
	if err != nil {
		return fmt.Errorf("encode message: %w", err)
	}

	req, err := http.NewRequestWithContext(
		ctx, http.MethodPost, p.cfg.Endpoint, bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("build request: %w", err)
	}
	req.Header.Set("api-key", p.cfg.APIKey)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")

	res, err := p.client.Do(req)
	if err != nil {
		p.log.Error("brevo_send_failed",
			slog.String("template", string(msg.Template)),
			slog.String("to", msg.To),
			slog.String("error", err.Error()),
		)
		return fmt.Errorf("send message: %w", err)
	}
	defer func() { _ = res.Body.Close() }()

	if res.StatusCode < 200 || res.StatusCode >= 300 {
		// The response explains a misconfiguration, such as an unverified sender, and
		// contains no part of the message.
		reason, _ := io.ReadAll(io.LimitReader(res.Body, 2048))
		p.log.Error("brevo_rejected_message",
			slog.Int("status", res.StatusCode),
			slog.String("to", msg.To),
			slog.String("reason", strings.TrimSpace(string(reason))),
		)
		return fmt.Errorf("brevo rejected the message: status %d", res.StatusCode)
	}

	p.log.Info("email_sent",
		slog.String("provider", "brevo"),
		slog.String("template", string(msg.Template)),
		slog.String("to", msg.To),
	)
	return nil
}
