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
	"strings"
)

// Config holds every setting the running service needs.
type Config struct {
	AppEnv   string
	Port     string
	LogLevel string

	// GitHubWebhookSecret verifies X-Hub-Signature-256 on incoming webhooks.
	GitHubWebhookSecret string

	// Telegram delivery credentials. Both are required for delivery to work.
	TelegramBotToken string
	TelegramChatID   string

	// CORSAllowedOrigins lists browser origins permitted to call this API. Empty means
	// no cross-origin request is allowed, which is the safe default for a deployment
	// that has not been configured yet.
	CORSAllowedOrigins []string
}

const (
	defaultAppEnv   = "development"
	defaultPort     = "8082"
	defaultLogLevel = "info"
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
		AppEnv:              getEnv("APP_ENV", defaultAppEnv),
		Port:                getEnv("PORT", defaultPort),
		LogLevel:            getEnv("LOG_LEVEL", defaultLogLevel),
		GitHubWebhookSecret: os.Getenv("GITHUB_WEBHOOK_SECRET"),
		TelegramBotToken:    os.Getenv("TELEGRAM_BOT_TOKEN"),
		TelegramChatID:      os.Getenv("TELEGRAM_CHAT_ID"),
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
	return nil
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
