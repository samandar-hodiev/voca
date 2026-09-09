// Fallback notifier used when Telegram credentials are absent.
//
// Local development and CI must work without vendor credentials, so an unconfigured
// service logs the notification instead of failing. This mirrors the mock-adapter pattern
// used for every other provider (ARCHITECTURE.md 7.3).
package devhook

import (
	"context"
	"log/slog"
)

// LogNotifier writes notifications to the log instead of delivering them.
type LogNotifier struct {
	log *slog.Logger
}

// NewLogNotifier builds the fallback notifier.
func NewLogNotifier(log *slog.Logger) *LogNotifier {
	return &LogNotifier{log: log}
}

// Name identifies the transport.
func (n *LogNotifier) Name() string { return "log" }

// Notify records the notification locally.
func (n *LogNotifier) Notify(_ context.Context, msg Notification) error {
	attrs := []any{slog.String("title", msg.Title)}
	for _, f := range msg.Fields {
		attrs = append(attrs, slog.String(f.Label, f.Value))
	}
	n.log.Info("devhook_notification_not_delivered_telegram_unconfigured", attrs...)
	return nil
}
