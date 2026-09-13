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

	"github.com/google/uuid"

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
	speechazure "github.com/samandar-hodiev/voca/backend/internal/integrations/speech/azure"
	speechmock "github.com/samandar-hodiev/voca/backend/internal/integrations/speech/mock"
	"github.com/samandar-hodiev/voca/backend/internal/integrations/storage/localfile"
	"github.com/samandar-hodiev/voca/backend/internal/integrations/telegram"
	"github.com/samandar-hodiev/voca/backend/internal/middleware"
	"github.com/samandar-hodiev/voca/backend/internal/practice"
	"github.com/samandar-hodiev/voca/backend/internal/progress"
	"github.com/samandar-hodiev/voca/backend/internal/pronunciation"
	"github.com/samandar-hodiev/voca/backend/internal/pronunciation/analysis"
	pronfeedback "github.com/samandar-hodiev/voca/backend/internal/pronunciation/feedback"
	"github.com/samandar-hodiev/voca/backend/internal/pronunciation/scoring"
	"github.com/samandar-hodiev/voca/backend/internal/pronunciation/validation"
	"github.com/samandar-hodiev/voca/backend/internal/subscription"
	"github.com/samandar-hodiev/voca/backend/internal/word"
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

	// Content, and the daily set built from it. The selector reads words through the word
	// module's SERVICE, never its tables, which is what keeps personalization a swap of
	// one implementation rather than a rewrite (ARCHITECTURE.md 13.2, 5.5).
	wordService := word.NewService(word.NewRepository(pool.Pool), log)
	practiceService := practice.NewService(
		practice.NewRepository(pool.Pool),
		practice.NewLevelSelector(wordService),
		learnersFromAuth{svc: authService},
		cfg.DailyPassScore,
		cfg.AppTimezone,
		log,
	)
	log.Info("daily_practice_configured", slog.Float64("pass_score", cfg.DailyPassScore))

	// Speech provider selection happens here and nowhere else. The mock is the default so
	// a fresh checkout runs the entire assessment pipeline — scoring, analysis, feedback,
	// persistence and the result screen — with no vendor account and no spend
	// (ARCHITECTURE.md 37, step 8).
	var speechProvider pronunciation.SpeechProvider = speechmock.New()
	switch cfg.SpeechProvider {
	case "azure":
		// A missing key or region is caught here, at startup, rather than on the first
		// learner's recording. Falling back to the mock keeps the server up, and the
		// warning says plainly that scores are no longer real.
		azureProvider, err := speechazure.New(speechazure.Config{
			Key:    cfg.AzureSpeechKey,
			Region: cfg.AzureSpeechRegion,
		}, log)
		if err != nil {
			log.Warn("speech_provider_azure_unavailable_using_mock",
				slog.String("error", err.Error()))
			break
		}
		speechProvider = azureProvider
		log.Info("speech_provider_selected",
			slog.String("provider", "azure"),
			slog.String("region", cfg.AzureSpeechRegion))
	default:
		log.Info("speech_provider_selected", slog.String("provider", "mock"))
	}

	// The daily quota. Policy lives in subscription; the counting stays inside
	// pronunciation, against its own table (ARCHITECTURE.md 9.4, 5.5).
	usageLimiter := subscription.NewUsageLimiter(
		accountsFromAuth{svc: authService},
		cfg.FreeDailyAssessmentLimit,
		cfg.UnlimitedAssessmentEmails,
		cfg.AppTimezone,
		log,
	)
	log.Info("usage_limit_configured",
		slog.Int("daily_limit", cfg.FreeDailyAssessmentLimit),
		slog.Int("unlimited_accounts", len(cfg.UnlimitedAssessmentEmails)))

	pronunciationService := pronunciation.NewService(
		pronunciation.NewRepository(pool.Pool),
		speechProvider,
		scoring.New(scoring.DefaultWeights()),
		analysis.New(analysis.DefaultThresholds()),
		pronfeedback.New(),
		validation.Limits{
			MaxBytes:      cfg.MaxAudioBytes,
			MinDurationMS: validation.DefaultLimits().MinDurationMS,
			MaxDurationMS: cfg.MaxAudioDurationMS,
		},
		entitlementsFromSubscription{limiter: usageLimiter},
		practiceService,
		log,
	)

	// The dashboard is derived from the attempts table rather than stored, so it needs no
	// migration and cannot drift from what it summarises.
	progressService := progress.NewService(
		progress.NewRepository(pool.Pool),
		learnersFromAuth{svc: authService},
		cfg.AppTimezone,
		log,
	)
	progressHandler := progress.NewHandler(progressService, log)

	devhookService := devhook.NewService(notifier, log)
	devhookHandler := devhook.NewHandler(devhookService, cfg.GitHubWebhookSecret, log)

	return Dependencies{
		Logger:               log,
		AvatarDir:            avatarStore.Dir(),
		AvatarPrefix:         avatarStore.PublicPrefix(),
		CORS:                 middleware.CORSConfig{AllowedOrigins: cfg.CORSAllowedOrigins},
		DevhookHandler:       devhookHandler,
		AuthHandler:          auth.NewHandler(authService),
		PronunciationHandler: pronunciation.NewHandler(pronunciationService),
		ProgressHandler:      progressHandler,
		WordHandler:          word.NewHandler(wordService, log),
		PracticeHandler:      practice.NewHandler(practiceService, log),
		RequireAuth:          middleware.RequireAuth(jwtVerifier{issuer}),
		TrustedProxies:       cfg.TrustedProxies,
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

// accountsFromAuth lets the usage limiter ask for a person's address without reaching into
// the auth module's storage. It goes through that module's SERVICE, which is the only
// surface another module may use (ARCHITECTURE.md 5.5).
type accountsFromAuth struct{ svc *auth.Service }

func (a accountsFromAuth) EmailByID(ctx context.Context, userID uuid.UUID) (string, error) {
	me, err := a.svc.Me(ctx, userID)
	if err != nil {
		return "", err
	}
	if me.User.Email == nil {
		// A guest has no address, and therefore no exemption. Not an error.
		return "", nil
	}
	return *me.User.Email, nil
}

// entitlementsFromSubscription converts the subscription module's answer into the shape
// the pronunciation module declared for itself. Neither module names the other; this
// composition root is the one place they meet.
type entitlementsFromSubscription struct{ limiter *subscription.UsageLimiter }

func (e entitlementsFromSubscription) Allowance(
	ctx context.Context, userID uuid.UUID,
) (pronunciation.Allowance, error) {
	a, err := e.limiter.Allowance(ctx, userID)
	if err != nil {
		return pronunciation.Allowance{}, err
	}
	return pronunciation.Allowance{
		Unlimited:  a.Unlimited,
		DailyLimit: a.DailyLimit,
		Since:      a.Since,
		ResetsAt:   a.ResetsAt,
	}, nil
}

// learnersFromAuth answers the progress module's questions about a person — the daily word
// goal and which midnight is theirs — through the auth module's service rather than its
// storage (ARCHITECTURE.md 5.5).
type learnersFromAuth struct{ svc *auth.Service }

func (l learnersFromAuth) DailyGoal(
	ctx context.Context, userID uuid.UUID,
) (int, string, error) {
	prefs, err := l.svc.Preferences(ctx, userID)
	if err != nil {
		return 0, "", err
	}
	return prefs.DailyGoalWords, prefs.Timezone, nil
}

// Settings answers the practice module's questions: which level to draw words from, how
// many a day, and whose midnight ends the day. Same adapter as the progress module uses,
// because it is the same underlying preferences row read through the same service.
func (l learnersFromAuth) Settings(
	ctx context.Context, userID uuid.UUID,
) (string, int, string, error) {
	prefs, err := l.svc.Preferences(ctx, userID)
	if err != nil {
		return "", 0, "", err
	}
	level := ""
	if prefs.CEFRLevel != nil {
		level = *prefs.CEFRLevel
	}
	return level, prefs.DailyGoalWords, prefs.Timezone, nil
}
