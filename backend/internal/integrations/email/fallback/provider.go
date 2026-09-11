// Package fallback keeps a development flow moving when the mail provider refuses.
//
// The problem it solves. A transactional mail provider will not send to an arbitrary
// recipient until the sender has verified a domain. Before that is done, every address
// except the account owner's is refused, and the refusal surfaces as an error on the very
// first screen of sign-up. Development stops on a configuration limit that has nothing to
// do with the code being written.
//
// So outside production, a refusal is not fatal: the message is written to the local
// outbox instead and the flow continues. The developer reads the code with `make code`,
// exactly as they would with no provider configured at all.
//
// This is DEVELOPMENT ONLY, and deliberately so:
//
//   - New refuses to run in production. There, a provider that will not send is a real
//     failure and must be reported as one. Quietly writing a customer's verification code
//     to a server disk and telling them it was sent would be far worse than an error.
//   - The fallback is logged at warning level every time it fires, so nobody mistakes a
//     restricted provider for a working one.
package fallback

import (
	"context"
	"errors"
	"log/slog"

	"github.com/samandar-hodiev/voca/backend/internal/auth"
)

// Provider tries a real sender first and falls back to a local one.
type Provider struct {
	primary  auth.EmailProvider
	local    auth.EmailProvider
	log      *slog.Logger
	primName string
}

// New wraps primary with local.
//
// production is passed in rather than read from the environment here so the guard is
// visible at the call site in the composition root.
func New(primary, local auth.EmailProvider, production bool,
	logger *slog.Logger) (*Provider, error) {

	if production {
		return nil, errors.New("fallback: must never run in production")
	}
	if primary == nil || local == nil {
		return nil, errors.New("fallback: both a primary and a local provider are required")
	}
	return &Provider{
		primary: primary, local: local, log: logger, primName: primary.Name(),
	}, nil
}

func (p *Provider) Name() string { return p.primName + "+outbox" }

// Send tries the real provider, then the local one.
//
// Only the local failure is returned. If the real provider refused but the message was
// written locally, the caller succeeded as far as it is concerned, because a developer can
// read the code.
func (p *Provider) Send(ctx context.Context, msg auth.EmailMessage) error {
	err := p.primary.Send(ctx, msg)
	if err == nil {
		return nil
	}

	p.log.Warn("email_fell_back_to_outbox",
		slog.String("provider", p.primName),
		slog.String("template", string(msg.Template)),
		slog.String("to", msg.To),
		slog.String("reason", err.Error()),
		slog.String("hint", "development only: read the code with `make code`"),
	)

	return p.local.Send(ctx, msg)
}
