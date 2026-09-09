// Voca API entrypoint.
//
// Responsibility, in order: load and validate configuration (fail fast on anything
// missing), build the logger, construct the object graph via internal/server, start the
// HTTP server, and handle SIGINT/SIGTERM for graceful shutdown.
//
// This is the single server entrypoint for the backend (ARCHITECTURE.md 28). There is
// deliberately no second cmd/server: competing entrypoints drift apart.
//
// Keep this file thin. It wires and starts; it decides nothing.
package main

import (
	"context"
	"log/slog"
	"os"
	"os/signal"
	"strings"
	"syscall"

	"github.com/gin-gonic/gin"

	"github.com/samandar-hodiev/voca/backend/internal/config"
	"github.com/samandar-hodiev/voca/backend/internal/server"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		slog.Error("config_load_failed", slog.String("error", err.Error()))
		os.Exit(1)
	}

	log := newLogger(cfg)

	// Startup diagnostics report whether each secret is PRESENT, never its value.
	log.Info("starting",
		slog.String("app_env", cfg.AppEnv),
		slog.String("port", cfg.Port),
		slog.Bool("github_webhook_configured", cfg.GitHubWebhookConfigured()),
		slog.Bool("telegram_configured", cfg.TelegramConfigured()),
	)

	if !cfg.GitHubWebhookConfigured() {
		log.Warn("github_webhook_secret_missing",
			slog.String("effect", "every webhook request will be rejected"),
			slog.String("hint", "set GITHUB_WEBHOOK_SECRET"))
	}

	if cfg.AppEnv == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	deps := server.Build(cfg, log)
	srv := server.New(cfg.Port, server.NewRouter(deps), log)

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	if err := srv.Start(ctx); err != nil {
		log.Error("server_failed", slog.String("error", err.Error()))
		os.Exit(1)
	}
	log.Info("server_stopped")
}

func newLogger(cfg config.Config) *slog.Logger {
	level := slog.LevelInfo
	switch strings.ToLower(cfg.LogLevel) {
	case "debug":
		level = slog.LevelDebug
	case "warn":
		level = slog.LevelWarn
	case "error":
		level = slog.LevelError
	}
	return slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: level}))
}
