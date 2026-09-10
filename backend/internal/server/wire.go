// The composition root — the ONLY place that knows the full object graph.
//
// Manual constructor injection, no DI framework: a monolith of this size does not need
// one, and explicit wiring is far easier for a new Go developer to read
// (ARCHITECTURE.md 5.7).
package server

import (
	"context"
	"log/slog"

	"github.com/samandar-hodiev/voca/backend/internal/auth"
	"github.com/samandar-hodiev/voca/backend/internal/config"
	"github.com/samandar-hodiev/voca/backend/internal/database"
	"github.com/samandar-hodiev/voca/backend/internal/devhook"
	emaillog "github.com/samandar-hodiev/voca/backend/internal/integrations/email/log"
	emailoutbox "github.com/samandar-hodiev/voca/backend/internal/integrations/email/outbox"
	emailsmtp "github.com/samandar-hodiev/voca/backend/internal/integrations/email/smtp"
	googleauth "github.com/samandar-hodiev/voca/backend/internal/integrations/google"
	"github.com/samandar-hodiev/voca/backend/internal/integrations/telegram"
	"github.com/samandar-hodiev/voca/backend/internal/middleware"
	"github.com/samandar-hodiev/voca/backend/pkg/jwt"
)

// Build constructs every dependency and returns the assembled router input.
//
// Returns an error rather than panicking: a misconfigured service must fail at startup
// with a readable message.
func Build(ctx context.Context, cfg config.Config, log *slog.Logger) (Dependencies, error) {
	pool, err := database.Open(ctx, database.Config{
		URL:      cfg.DatabaseURL,
		MaxConns: cfg.DatabaseMaxConns,
	})
	if err != nil {
		return Dependencies{}, err
	}

	issuer, err := jwt.NewIssuer(cfg.JWTSecret, cfg.JWTAccessTTL)
	if err != nil {
		return Dependencies{}, err
	}

	// Email provider selection, most capable first (ARCHITECTURE.md 18.4).
	//
	//   SMTP configured    -> real delivery to a real inbox
	//   EMAIL_OUTBOX_DIR   -> written to disk for a developer to read (never production)
	//   neither            -> the log provider, which says a message would have been sent
	//                         and never reveals the code
	var emailProvider auth.EmailProvider = emaillog.New(log)
	switch {
	case cfg.SMTPConfigured():
		sender, err := emailsmtp.New(emailsmtp.Config{
			Host:     cfg.SMTPHost,
			Port:     cfg.SMTPPort,
			Username: cfg.SMTPUsername,
			Password: cfg.SMTPPassword,
			From:     cfg.SMTPFrom,
			FromName: cfg.SMTPFromName,
		}, log)
		if err != nil {
			return Dependencies{}, err
		}
		emailProvider = sender
		log.Info("email_provider_selected",
			slog.String("provider", "smtp"),
			slog.String("host", cfg.SMTPHost))

	case cfg.EmailOutboxEnabled():
		box, err := emailoutbox.New(cfg.EmailOutboxDir, cfg.IsProduction(), log)
		if err != nil {
			return Dependencies{}, err
		}
		emailProvider = box
		log.Warn("email_outbox_enabled",
			slog.String("dir", cfg.EmailOutboxDir),
			slog.String("hint", "development only: messages are written to disk, not sent"))

	default:
		log.Warn("email_delivery_unavailable",
			slog.String("hint", "set SMTP_HOST, SMTP_FROM and credentials to deliver real email"))
	}

	// Google sign-in verifies tokens against Google's keys. With no client ID configured
	// it fails closed, and the app reads that from /api/v1/config to disable the button.
	googleVerifier := googleauth.New(cfg.GoogleClientIDs)
	if !googleVerifier.Configured() {
		log.Warn("google_signin_unavailable",
			slog.String("hint", "set GOOGLE_IOS_CLIENT_ID or GOOGLE_ANDROID_CLIENT_ID"))
	}

	authService := auth.NewService(
		auth.NewRepository(pool.Pool), issuer, emailProvider,
		googleVerifier, auth.DefaultPolicy(), log)

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
		AuthHandler:    auth.NewHandler(authService),
		RequireAuth:    middleware.RequireAuth(jwtVerifier{issuer}),
		DB:             pool,
		Capabilities: Capabilities{
			GoogleSignIn: googleVerifier.Configured(),
			// Apple needs an Apple Developer configuration that does not exist yet.
			AppleSignIn: false,
		},
	}, nil
}

// jwtVerifier adapts the JWT issuer to the middleware's port.
//
// The port takes a context because a future verifier may need one, for example to check a
// revocation list. The JWT issuer does not, so the adapter simply drops it. Writing the
// adapter here rather than widening either side keeps both interfaces honest.
type jwtVerifier struct{ issuer *jwt.Issuer }

func (v jwtVerifier) VerifyAccessToken(_ context.Context, raw string) (string, error) {
	return v.issuer.Verify(raw)
}
