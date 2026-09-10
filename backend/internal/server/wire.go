// The composition root — the ONLY place that knows the full object graph.
//
// Manual constructor injection, no DI framework: a monolith of this size does not need
// one, and explicit wiring is far easier for a new Go developer to read
// (ARCHITECTURE.md 5.7).
package server

import (
	"log/slog"

	"github.com/samandar-hodiev/voca/backend/internal/config"
	"github.com/samandar-hodiev/voca/backend/internal/devhook"
	"github.com/samandar-hodiev/voca/backend/internal/integrations/telegram"
	"github.com/samandar-hodiev/voca/backend/internal/middleware"
)

// Build constructs every dependency and returns the assembled router input.
func Build(cfg config.Config, log *slog.Logger) Dependencies {
	// Provider selection happens here and nowhere else. Without Telegram credentials the
	// service still runs and logs what it would have sent, so local development and CI
	// need no vendor secrets (ARCHITECTURE.md 7.3).
	var notifier devhook.Notifier
	if cfg.TelegramConfigured() {
		notifier = telegram.New(cfg.TelegramBotToken, cfg.TelegramChatID)
	} else {
		log.Warn("telegram_not_configured_using_log_notifier",
			slog.String("hint", "set TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID to enable delivery"))
		notifier = devhook.NewLogNotifier(log)
	}

	devhookService := devhook.NewService(notifier, log)
	devhookHandler := devhook.NewHandler(devhookService, cfg.GitHubWebhookSecret, log)

	return Dependencies{
		Logger:         log,
		CORS:           middleware.CORSConfig{AllowedOrigins: cfg.CORSAllowedOrigins},
		DevhookHandler: devhookHandler,
	}
}
