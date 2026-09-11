// The composition root — the ONLY place that knows the full object graph.
//
// Manual constructor injection, no DI framework: a monolith of this size does not need
// one, and explicit wiring is far easier for a new Go developer to read
// (ARCHITECTURE.md 5.7).
package server

import (
	"context"
	"log/slog"
	"time"

	"github.com/samandar-hodiev/voca/backend/internal/auth"
	"github.com/samandar-hodiev/voca/backend/internal/config"
	"github.com/samandar-hodiev/voca/backend/internal/database"
	"github.com/samandar-hodiev/voca/backend/internal/devhook"
	emailbrevo "github.com/samandar-hodiev/voca/backend/internal/integrations/email/brevo"
	emailfallback "github.com/samandar-hodiev/voca/backend/internal/integrations/email/fallback"
	emaillog "github.com/samandar-hodiev/voca/backend/internal/integrations/email/log"
	emailoutbox "github.com/samandar-hodiev/voca/backend/internal/integrations/email/outbox"
	emailresend "github.com/samandar-hodiev/voca/backend/internal/integrations/email/resend"
	emailsmtp "github.com/samandar-hodiev/voca/backend/internal/integrations/email/smtp"
	firebaseauth "github.com/samandar-hodiev/voca/backend/internal/integrations/firebase"
	"github.com/samandar-hodiev/voca/backend/internal/integrations/storage/localfile"
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
	//   Brevo configured   -> real delivery over HTTPS, sender address only
	//   Resend configured  -> real delivery over HTTPS, verified domain
	//   SMTP configured    -> real delivery to a real inbox
	//   EMAIL_OUTBOX_DIR   -> written to disk for a developer to read (never production)
	//   neither            -> the log provider, which says a message would have been sent
	//                         and never reveals the code
	var emailProvider auth.EmailProvider = emaillog.New(log)
	switch {
	case cfg.BrevoConfigured():
		sender, err := emailbrevo.New(emailbrevo.Config{
			APIKey:   cfg.BrevoAPIKey,
			From:     cfg.BrevoFrom,
			FromName: cfg.BrevoFromName,
		}, log)
		if err != nil {
			return Dependencies{}, err
		}
		emailProvider = sender
		log.Info("email_provider_selected", slog.String("provider", "brevo"))

	case cfg.ResendConfigured():
		sender, err := emailresend.New(emailresend.Config{
			APIKey:   cfg.ResendAPIKey,
			From:     cfg.ResendFrom,
			FromName: cfg.ResendFromName,
		}, log)
		if err != nil {
			return Dependencies{}, err
		}
		emailProvider = sender
		log.Info("email_provider_selected", slog.String("provider", "resend"))

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
			slog.String("hint", "set BREVO_API_KEY and BREVO_FROM, or RESEND_API_KEY and RESEND_FROM"))
	}

	// Outside production, a provider that refuses a recipient must not stop development.
	// Until a domain is verified a mail API will only deliver to the account owner, and
	// without this every other address fails on the first screen of sign-up. The message
	// is written to the outbox instead and the flow continues.
	if !cfg.IsProduction() && cfg.EmailOutboxDir != "" &&
		(cfg.BrevoConfigured() || cfg.ResendConfigured() || cfg.SMTPConfigured()) {

		box, err := emailoutbox.New(cfg.EmailOutboxDir, cfg.IsProduction(), log)
		if err != nil {
			return Dependencies{}, err
		}
		wrapped, err := emailfallback.New(emailProvider, box, cfg.IsProduction(), log)
		if err != nil {
			return Dependencies{}, err
		}
		emailProvider = wrapped
		log.Warn("email_outbox_fallback_enabled",
			slog.String("hint", "development only: a refused recipient is written to disk"))
	}

	// Google sign-in arrives as a Firebase ID token and is verified against Google's
	// published certificates. With no project configured it fails closed, and the app
	// reads that from /api/v1/config to disable the button rather than offer one that
	// cannot succeed.
	googleVerifier := firebaseauth.New(ctx, cfg.FirebaseProjectID)
	if !googleVerifier.Configured() {
		log.Warn("google_signin_unavailable",
			slog.String("hint", "set FIREBASE_PROJECT_ID"))
	}

	// Avatars are written to a local directory and served back as static files. Object
	// storage is the eventual home; swapping it is a new adapter behind the same port.
	avatarStore, err := localfile.NewAvatarStore(cfg.AvatarDir, avatarURLPrefix)
	if err != nil {
		return Dependencies{}, err
	}

	authService := auth.NewService(
		auth.NewRepository(pool.Pool), issuer, emailProvider,
		googleVerifier, avatarStore, auth.DefaultPolicy(), log)

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
		AvatarDir:      avatarStore.Dir(),
		AvatarPrefix:   avatarStore.PublicPrefix(),
		CORS:           middleware.CORSConfig{AllowedOrigins: cfg.CORSAllowedOrigins},
		DevhookHandler: devhookHandler,
		AuthHandler:    auth.NewHandler(authService),
		RequireAuth:    middleware.RequireAuth(jwtVerifier{issuer}),
		TrustedProxies: cfg.TrustedProxies,
		AuthRateLimit: middleware.RateLimit(middleware.RateLimitConfig{
			Requests: cfg.AuthRateLimitPerMin,
			Window:   time.Minute,
		}),
		DB: pool,
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
