// HTTP server lifecycle.
//
// Graceful shutdown is not optional: it is what makes zero-downtime rolling deploys work
// (ARCHITECTURE.md 24.4).
package server

import (
	"context"
	"errors"
	"log/slog"
	"net"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// Server wraps the HTTP server and its lifecycle.
type Server struct {
	http *http.Server
	log  *slog.Logger
}

// New builds the server bound to the given port.
func New(port string, handler *gin.Engine, log *slog.Logger) *Server {
	return &Server{
		http: &http.Server{
			Addr:              net.JoinHostPort("", port),
			Handler:           handler,
			ReadHeaderTimeout: 10 * time.Second,
			ReadTimeout:       30 * time.Second,
			WriteTimeout:      30 * time.Second,
			IdleTimeout:       60 * time.Second,
		},
		log: log,
	}
}

// Addr reports the address the server listens on.
func (s *Server) Addr() string { return s.http.Addr }

// Start begins serving and blocks until the context is cancelled, then drains.
func (s *Server) Start(ctx context.Context) error {
	errCh := make(chan error, 1)

	go func() {
		s.log.Info("server_listening", slog.String("addr", s.http.Addr))
		if err := s.http.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			errCh <- err
		}
	}()

	select {
	case err := <-errCh:
		return err
	case <-ctx.Done():
		s.log.Info("server_shutting_down")
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
		defer cancel()
		return s.http.Shutdown(shutdownCtx)
	}
}
