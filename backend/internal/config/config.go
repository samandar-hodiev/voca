// Package config loads typed application configuration from environment variables.
//
// Twelve-factor: no config file with secrets lives in the repository. Values are read
// once at startup and validated, so the process fails fast rather than discovering a
// missing secret on the first request.
//
// Secrets are held in memory only and are NEVER logged (ARCHITECTURE.md 18.4, 25.2).
package config

import (
	"bufio"
	"errors"
	"os"
	"strconv"
	"strings"
	"time"
)

// Config holds every setting the running service needs.
type Config struct {
	AppEnv   string
	Port     string
	LogLevel string

	// DatabaseURL is required in every environment. There is no in-memory fallback: a
	// service that silently runs without its database is worse than one that refuses to
	// start.
	DatabaseURL      string
	DatabaseMaxConns int32

	// JWTSecret signs access tokens. Required: a service that signs with a predictable
	// key is worse than one that refuses to start.
	JWTSecret    string
	JWTAccessTTL time.Duration

	// GoogleClientIDs are the OAuth audiences this backend accepts, one per platform.
	// Empty means Google sign-in is unavailable, and the app is told so rather than
	// shown a button that cannot work.
	GoogleClientIDs []string

	// GitHubWebhookSecret verifies X-Hub-Signature-256 on incoming webhooks.
	GitHubWebhookSecret string

	// Telegram delivery credentials. Both are required for delivery to work.
	TelegramBotToken string
	TelegramChatID   string

	// Brevo delivers real email over HTTPS and needs only a verified sender address,
	// not a verified domain, so it can be used before the product owns one.
	BrevoAPIKey   string
	BrevoFrom     string
	BrevoFromName string

	// Resend delivers real email over HTTPS. Preferred over SMTP because ports 587 and
	// 465 are blocked on many networks, while 443 is always open.
	ResendAPIKey   string
	ResendFrom     string
	ResendFromName string

	// SMTP delivers real email. Configured means a person actually receives the
	// verification code. Unset falls back to the outbox or the log provider, neither of
	// which leaves the machine.
	SMTPHost     string
	SMTPPort     int
	SMTPUsername string
	SMTPPassword string
	SMTPFrom     string
	SMTPFromName string

	// EmailOutboxDir turns on the local mail catcher outside production: every message
	// the service sends is written there as a file so a developer can read a
	// verification code without mail credentials. Empty keeps the log provider, which
	// never reveals a code. Ignored entirely in production.
	EmailOutboxDir string

	// CORSAllowedOrigins lists browser origins permitted to call this API. Empty means
	// no cross-origin request is allowed, which is the safe default for a deployment
	// that has not been configured yet.
	CORSAllowedOrigins []string
}

const (
	defaultAppEnv   = "development"
	defaultPort     = "8082"
	defaultLogLevel = "info"

	// A local development default so a new developer can run the backend after creating
	// the database and nothing else. Deployments always set DATABASE_URL explicitly.
	defaultDatabaseURL = "postgres://localhost:5432/voca_dev?sslmode=disable"
)

// Load reads configuration from the process environment.
//
// If a .env file exists it is read first as a local-development convenience, but real
// environment variables always take precedence, so a stray file can never override a
// deployed configuration.
func Load() (Config, error) {
	loadDotEnv(".env")
	loadDotEnv("backend/.env")

	cfg := Config{
		AppEnv:           getEnv("APP_ENV", defaultAppEnv),
		Port:             getEnv("PORT", defaultPort),
		LogLevel:         getEnv("LOG_LEVEL", defaultLogLevel),
		DatabaseURL:      getEnv("DATABASE_URL", defaultDatabaseURL),
		DatabaseMaxConns: int32(getEnvInt("DATABASE_MAX_CONNS", 20)),
		JWTSecret:        os.Getenv("JWT_SECRET"),
		JWTAccessTTL:     getEnvDuration("JWT_ACCESS_TTL", 15*time.Minute),
		GoogleClientIDs: splitAndTrim(os.Getenv("GOOGLE_IOS_CLIENT_ID") + "," +
			os.Getenv("GOOGLE_ANDROID_CLIENT_ID") + "," + os.Getenv("GOOGLE_WEB_CLIENT_ID")),
		GitHubWebhookSecret: os.Getenv("GITHUB_WEBHOOK_SECRET"),
		TelegramBotToken:    os.Getenv("TELEGRAM_BOT_TOKEN"),
		TelegramChatID:      os.Getenv("TELEGRAM_CHAT_ID"),
		BrevoAPIKey:         strings.TrimSpace(os.Getenv("BREVO_API_KEY")),
		BrevoFrom:           strings.TrimSpace(os.Getenv("BREVO_FROM")),
		BrevoFromName:       getEnv("BREVO_FROM_NAME", "Voca"),
		ResendAPIKey:        strings.TrimSpace(os.Getenv("RESEND_API_KEY")),
		ResendFrom:          strings.TrimSpace(os.Getenv("RESEND_FROM")),
		ResendFromName:      getEnv("RESEND_FROM_NAME", "Voca"),
		SMTPHost:            strings.TrimSpace(os.Getenv("SMTP_HOST")),
		SMTPPort:            getEnvInt("SMTP_PORT", 587),
		SMTPUsername:        strings.TrimSpace(os.Getenv("SMTP_USERNAME")),
		SMTPPassword:        os.Getenv("SMTP_PASSWORD"),
		SMTPFrom:            strings.TrimSpace(os.Getenv("SMTP_FROM")),
		SMTPFromName:        strings.TrimSpace(os.Getenv("SMTP_FROM_NAME")),
		EmailOutboxDir:      strings.TrimSpace(os.Getenv("EMAIL_OUTBOX_DIR")),
		CORSAllowedOrigins:  splitAndTrim(os.Getenv("CORS_ALLOWED_ORIGINS")),
	}

	if err := cfg.validate(); err != nil {
		return Config{}, err
	}
	return cfg, nil
}

func (c Config) validate() error {
	if strings.TrimSpace(c.Port) == "" {
		return errors.New("config: PORT must not be empty")
	}
	if strings.TrimSpace(c.DatabaseURL) == "" {
		return errors.New("config: DATABASE_URL must not be empty")
	}
	if strings.TrimSpace(c.JWTSecret) == "" {
		return errors.New("config: JWT_SECRET must not be empty")
	}
	return nil
}

// IsProduction reports whether this process is serving real people.
//
// Development-only behaviour is gated on it, so the check lives in one place instead of
// being spelled slightly differently at each call site.
func (c Config) IsProduction() bool {
	return strings.EqualFold(strings.TrimSpace(c.AppEnv), "production")
}

// BrevoConfigured reports whether the Brevo HTTP mail API can be used.
func (c Config) BrevoConfigured() bool {
	return c.BrevoAPIKey != "" && c.BrevoFrom != ""
}

// ResendConfigured reports whether the HTTP mail API can be used.
func (c Config) ResendConfigured() bool {
	return c.ResendAPIKey != "" && c.ResendFrom != ""
}

// SMTPConfigured reports whether real email can be delivered.
//
// A host and a sender are the minimum. Username and password are optional because a
// relay on a private network may not require authentication.
func (c Config) SMTPConfigured() bool {
	return c.SMTPHost != "" && c.SMTPFrom != "" && c.SMTPPort > 0
}

// EmailOutboxEnabled reports whether the local mail catcher should be used.
//
// Production can never enable it, whatever the environment says.
func (c Config) EmailOutboxEnabled() bool {
	return !c.IsProduction() && c.EmailOutboxDir != ""
}

// TelegramConfigured reports whether notifications can actually be delivered.
// Used to choose the real client or a logging fallback at wiring time.
func (c Config) TelegramConfigured() bool {
	return c.TelegramBotToken != "" && c.TelegramChatID != ""
}

// GitHubWebhookConfigured reports whether incoming webhooks can be verified.
// Without a secret every webhook request is rejected, which is the safe default.
func (c Config) GitHubWebhookConfigured() bool {
	return c.GitHubWebhookSecret != ""
}

func getEnv(key, fallback string) string {
	if v := strings.TrimSpace(os.Getenv(key)); v != "" {
		return v
	}
	return fallback
}

// loadDotEnv reads simple KEY=VALUE lines. Existing environment variables are never
// overwritten. Missing files are not an error.
func loadDotEnv(path string) {
	f, err := os.Open(path)
	if err != nil {
		return
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		key, value, found := strings.Cut(line, "=")
		if !found {
			continue
		}
		key = strings.TrimSpace(key)
		value = strings.TrimSpace(value)
		value = strings.Trim(value, `"'`)
		if key == "" {
			continue
		}
		if _, exists := os.LookupEnv(key); exists {
			continue
		}
		_ = os.Setenv(key, value)
	}
}

// splitAndTrim turns a comma-separated environment value into a clean slice.
func splitAndTrim(v string) []string {
	if strings.TrimSpace(v) == "" {
		return nil
	}
	parts := strings.Split(v, ",")
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		if p = strings.TrimSpace(p); p != "" {
			out = append(out, p)
		}
	}
	return out
}

// getEnvBool reads a boolean setting. Anything that is not a recognised true value is
// false, so a typo disables a feature rather than silently enabling it.
func getEnvBool(key string, fallback bool) bool {
	raw := strings.ToLower(strings.TrimSpace(os.Getenv(key)))
	if raw == "" {
		return fallback
	}
	return raw == "1" || raw == "true" || raw == "yes" || raw == "on"
}

// getEnvInt reads an integer setting, falling back when unset or unparseable.
func getEnvInt(key string, fallback int) int {
	raw := strings.TrimSpace(os.Getenv(key))
	if raw == "" {
		return fallback
	}
	v, err := strconv.Atoi(raw)
	if err != nil {
		return fallback
	}
	return v
}

// getEnvDuration reads a duration setting such as "15m", falling back when unset or
// unparseable.
func getEnvDuration(key string, fallback time.Duration) time.Duration {
	raw := strings.TrimSpace(os.Getenv(key))
	if raw == "" {
		return fallback
	}
	d, err := time.ParseDuration(raw)
	if err != nil {
		return fallback
	}
	return d
}
