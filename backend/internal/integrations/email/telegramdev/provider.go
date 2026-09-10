// Package telegramdev delivers development mail to a Telegram chat.
//
// Why this exists. On a network that blocks outbound ports 587 and 465 there is no SMTP
// path at all, and until a transactional mail API key exists the only place a code can go
// is a file on the developer's disk. That works, but it means switching to a terminal
// every time somebody wants to sign in on a phone. Telegram's API is HTTPS on 443, which
// is open everywhere, so the code can reach the same phone the app is running on within a
// second or two.
//
// This is a DEVELOPMENT channel and nothing more:
//
//   - It refuses to run in production. A verification code belongs in the recipient's
//     inbox, not in a chat the developer owns, and a deployment that reached this
//     provider would be sending every customer's code to one person.
//   - The intended recipient is written into the message, so it is obvious that the code
//     was addressed to somebody else.
//   - The code is never logged.
//
// See docs/runbooks/local-development.md.
package telegramdev

import (
	"context"
	"errors"
	"fmt"
	"html"
	"io"
	"log/slog"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/samandar-hodiev/voca/backend/internal/auth"
	"github.com/samandar-hodiev/voca/backend/internal/integrations/email/template"
)

const defaultTimeout = 10 * time.Second

// Config is what the provider needs.
type Config struct {
	BotToken string
	ChatID   string

	// BaseURL is overridden by tests. Empty means the real Telegram API.
	BaseURL string

	Timeout time.Duration
}

// Provider posts development mail to a chat.
type Provider struct {
	cfg    Config
	client *http.Client
	log    *slog.Logger
}

// New validates the configuration and returns a provider.
//
// production is passed in rather than read from the environment here so the guard is
// visible at the call site in the composition root.
func New(cfg Config, production bool, logger *slog.Logger) (*Provider, error) {
	if production {
		return nil, errors.New("telegramdev: must never run in production")
	}
	if strings.TrimSpace(cfg.BotToken) == "" || strings.TrimSpace(cfg.ChatID) == "" {
		return nil, errors.New("telegramdev: bot token and chat id are required")
	}
	if cfg.BaseURL == "" {
		cfg.BaseURL = "https://api.telegram.org"
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

func (p *Provider) Name() string { return "telegram-dev" }

// Send posts the message to the configured chat.
func (p *Provider) Send(ctx context.Context, msg auth.EmailMessage) error {
	if strings.TrimSpace(msg.To) == "" {
		return errors.New("telegramdev: recipient is required")
	}

	endpoint := fmt.Sprintf("%s/bot%s/sendMessage", p.cfg.BaseURL, p.cfg.BotToken)

	form := url.Values{
		"chat_id":    {p.cfg.ChatID},
		"parse_mode": {"HTML"},
		"text":       {p.render(msg)},
	}

	req, err := http.NewRequestWithContext(
		ctx, http.MethodPost, endpoint, strings.NewReader(form.Encode()))
	if err != nil {
		return fmt.Errorf("build request: %w", err)
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	res, err := p.client.Do(req)
	if err != nil {
		// The error never carries the message body, so a delivery failure stays
		// debuggable without the code appearing in a log file.
		p.log.Error("telegram_dev_send_failed",
			slog.String("template", string(msg.Template)),
			slog.String("to", msg.To),
			slog.String("error", err.Error()),
		)
		return fmt.Errorf("send message: %w", err)
	}
	defer func() { _ = res.Body.Close() }()

	if res.StatusCode < 200 || res.StatusCode >= 300 {
		reason, _ := io.ReadAll(io.LimitReader(res.Body, 1024))
		p.log.Error("telegram_dev_rejected",
			slog.Int("status", res.StatusCode),
			slog.String("reason", strings.TrimSpace(string(reason))),
		)
		return fmt.Errorf("telegram rejected the message: status %d", res.StatusCode)
	}

	p.log.Info("email_sent",
		slog.String("provider", "telegram-dev"),
		slog.String("template", string(msg.Template)),
		slog.String("to", msg.To),
	)
	return nil
}

// render builds the chat message.
//
// The intended recipient is stated first so it is never mistaken for a message meant for
// whoever is reading the chat.
func (p *Provider) render(msg auth.EmailMessage) string {
	var b strings.Builder
	b.WriteString("🔑 <b>Voca — development</b>\n")
	b.WriteString("Bu xabar pochta o‘rniga shu chatga yuborildi.\n\n")
	fmt.Fprintf(&b, "<b>Kimga:</b> %s\n", html.EscapeString(msg.To))
	fmt.Fprintf(&b, "<b>Mavzu:</b> %s\n\n", html.EscapeString(template.Subject(msg.Template)))

	if code := msg.Params["code"]; code != "" {
		fmt.Fprintf(&b, "<b>Kod:</b> <code>%s</code>\n\n", html.EscapeString(code))
	}
	b.WriteString(html.EscapeString(template.Body(msg)))
	return b.String()
}
