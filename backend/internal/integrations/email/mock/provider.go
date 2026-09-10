// Package mock is the test email provider.
//
// It records what would have been sent so a test can assert on delivery without a
// network call, and can be made to fail on demand.
package mock

import (
	"context"
	"sync"

	"github.com/samandar-hodiev/voca/backend/internal/auth"
)

type Provider struct {
	mu   sync.Mutex
	sent []auth.EmailMessage
	err  error
}

func New() *Provider { return &Provider{} }

func (p *Provider) Name() string { return "mock" }

// FailWith makes every subsequent Send return err.
func (p *Provider) FailWith(err error) {
	p.mu.Lock()
	defer p.mu.Unlock()
	p.err = err
}

func (p *Provider) Send(_ context.Context, msg auth.EmailMessage) error {
	p.mu.Lock()
	defer p.mu.Unlock()
	if p.err != nil {
		return p.err
	}
	p.sent = append(p.sent, msg)
	return nil
}

// Sent returns a copy of everything delivered so far.
func (p *Provider) Sent() []auth.EmailMessage {
	p.mu.Lock()
	defer p.mu.Unlock()
	return append([]auth.EmailMessage(nil), p.sent...)
}

// Last returns the most recent message, or false when nothing was sent.
func (p *Provider) Last() (auth.EmailMessage, bool) {
	p.mu.Lock()
	defer p.mu.Unlock()
	if len(p.sent) == 0 {
		return auth.EmailMessage{}, false
	}
	return p.sent[len(p.sent)-1], true
}
