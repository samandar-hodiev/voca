// Business logic for repository events.
//
// The handler stays thin; everything that decides WHAT happens lives here
// (ARCHITECTURE.md 5.3).
package devhook

import (
	"context"
	"fmt"
	"log/slog"
	"strconv"
	"time"
)

// notifyTimeout bounds the outbound call. GitHub expects a fast response and gives up
// after about 10s, so the notification must never hold the request open longer than this.
const notifyTimeout = 5 * time.Second

// Service turns verified repository events into notifications.
type Service struct {
	notifier Notifier
	log      *slog.Logger
}

// NewService builds the service. The notifier is injected, which is what makes the whole
// flow testable without touching Telegram.
func NewService(notifier Notifier, log *slog.Logger) *Service {
	return &Service{notifier: notifier, log: log}
}

// HandlePush composes and delivers the notification for a push event.
func (s *Service) HandlePush(ctx context.Context, ev PushEvent) error {
	n := buildPushNotification(ev)

	ctx, cancel := context.WithTimeout(ctx, notifyTimeout)
	defer cancel()

	if err := s.notifier.Notify(ctx, n); err != nil {
		return fmt.Errorf("devhook: notify via %s: %w", s.notifier.Name(), err)
	}

	s.log.Info("devhook_push_notified",
		slog.String("repository", ev.Repository),
		slog.String("branch", ev.Branch),
		slog.Int("commits", ev.CommitCount),
		slog.String("transport", s.notifier.Name()),
	)
	return nil
}

// buildPushNotification defines what a push notification says. Kept separate from
// delivery so the wording can be tested directly and changed without touching transport.
func buildPushNotification(ev PushEvent) Notification {
	fields := []Field{
		{Label: "Repository", Value: ev.Repository},
		{Label: "Branch", Value: ev.Branch},
		{Label: "Author", Value: ev.Pusher},
		{Label: "Commits", Value: strconv.Itoa(ev.CommitCount)},
	}
	if ev.LatestMessage != "" {
		fields = append(fields, Field{Label: "Latest", Value: ev.LatestMessage})
	}

	link := ev.LatestURL
	if link == "" {
		link = ev.CompareURL
	}

	return Notification{
		Title:  "🚀 New push to Voca",
		Fields: fields,
		Link:   link,
	}
}
