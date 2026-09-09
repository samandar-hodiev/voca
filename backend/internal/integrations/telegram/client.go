// Package telegram delivers developer notifications through the Telegram Bot API.
//
// This is the ONLY package that knows Telegram exists. It implements devhook.Notifier,
// an interface owned by the consumer, so replacing Telegram with Slack or e-mail is a new
// adapter and nothing else changes (ARCHITECTURE.md 7.1, ADR-006).
//
// The bot token is held in memory and is NEVER logged, never placed in an error message,
// and never returned to a client (ARCHITECTURE.md 18.4).
package telegram

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/samandar-hodiev/voca/backend/internal/devhook"
)

const apiBase = "https://api.telegram.org"

// Client sends messages to a single chat.
type Client struct {
	token   string
	chatID  string
	baseURL string
	http    *http.Client
}

// New builds a Telegram client. Credentials come from configuration, never from a literal.
func New(token, chatID string) *Client {
	return &Client{
		token:   token,
		chatID:  chatID,
		baseURL: apiBase,
		http:    &http.Client{Timeout: 10 * time.Second},
	}
}

// Name identifies the transport, for logging.
func (c *Client) Name() string { return "telegram" }

// sendMessageRequest is the Telegram API request body.
//
// parse_mode is deliberately OMITTED, so the message is sent as plain text. Commit
// messages and branch names are attacker-influenced content; enabling HTML or Markdown
// would mean escaping every value correctly forever. Telegram still auto-links bare URLs,
// so nothing is lost.
type sendMessageRequest struct {
	ChatID            string `json:"chat_id"`
	Text              string `json:"text"`
	DisableWebPreview bool   `json:"disable_web_page_preview"`
}

type sendMessageResponse struct {
	OK          bool   `json:"ok"`
	ErrorCode   int    `json:"error_code"`
	Description string `json:"description"`
}

// Notify renders and delivers the notification.
func (c *Client) Notify(ctx context.Context, n devhook.Notification) error {
	body, err := json.Marshal(sendMessageRequest{
		ChatID:            c.chatID,
		Text:              render(n),
		DisableWebPreview: true,
	})
	if err != nil {
		return fmt.Errorf("telegram: encode request: %w", err)
	}

	// The token sits in the URL path, which is why no error below ever includes the URL.
	endpoint := fmt.Sprintf("%s/bot%s/sendMessage", c.baseURL, c.token)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("telegram: build request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.http.Do(req)
	if err != nil {
		// net/http errors embed the request URL, which contains the token, so the
		// underlying error is deliberately NOT wrapped in.
		return fmt.Errorf("telegram: request failed: %w", redactError(err, c.token))
	}
	defer resp.Body.Close()

	var out sendMessageResponse
	if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
		return fmt.Errorf("telegram: unexpected response (status %d)", resp.StatusCode)
	}
	if !out.OK {
		return fmt.Errorf("telegram: api rejected message (status %d, code %d): %s",
			resp.StatusCode, out.ErrorCode, out.Description)
	}
	return nil
}

// render turns a provider-neutral notification into Telegram message text.
func render(n devhook.Notification) string {
	var b strings.Builder
	b.WriteString(n.Title)
	b.WriteString("\n\n")
	for _, f := range n.Fields {
		b.WriteString(f.Label)
		b.WriteString(": ")
		b.WriteString(f.Value)
		b.WriteByte('\n')
	}
	if n.Link != "" {
		b.WriteByte('\n')
		b.WriteString(n.Link)
	}
	return b.String()
}

// redactError removes the bot token from an error string before it reaches a log.
func redactError(err error, token string) error {
	if err == nil || token == "" {
		return err
	}
	if msg := err.Error(); strings.Contains(msg, token) {
		return fmt.Errorf("%s", strings.ReplaceAll(msg, token, "REDACTED"))
	}
	return err
}
