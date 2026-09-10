// Package google verifies Sign in with Google identity tokens.
//
// This is the ONLY package that knows Google exists. It implements
// auth.GoogleTokenVerifier, an interface the auth module owns.
//
// Verification happens SERVER-SIDE against Google's public keys. Trusting a token the app
// simply forwards, without checking its signature and audience, would let anyone sign in
// as anyone by crafting one (ARCHITECTURE.md 8.1).
package google

import (
	"context"
	"errors"
	"fmt"

	"google.golang.org/api/idtoken"

	"github.com/samandar-hodiev/voca/backend/internal/auth"
)

// ErrNotConfigured means no OAuth client ID was supplied, so no token can be trusted.
var ErrNotConfigured = errors.New("google: no client ID configured")

// Verifier checks tokens against Google's published keys.
type Verifier struct {
	// clientIDs are the audiences this backend accepts: one per platform, because iOS,
	// Android and web each get their own OAuth client.
	clientIDs []string
}

// New builds a verifier. An empty list is allowed and makes every verification fail
// closed, which is what lets the app show the button as unavailable rather than broken.
func New(clientIDs []string) *Verifier {
	return &Verifier{clientIDs: clientIDs}
}

// Configured reports whether Google sign-in can work at all.
func (v *Verifier) Configured() bool { return len(v.clientIDs) > 0 }

// Verify validates the token and returns the identity behind it.
func (v *Verifier) Verify(ctx context.Context, token string) (auth.GoogleIdentity, error) {
	if !v.Configured() {
		return auth.GoogleIdentity{}, ErrNotConfigured
	}

	// A token is accepted if it was issued for ANY of our clients. idtoken.Validate
	// checks the signature against Google's rotating keys, the issuer, the expiry and the
	// audience; all of those matter, and the audience most of all, because a valid Google
	// token issued to a DIFFERENT application would otherwise be accepted here.
	var lastErr error
	for _, audience := range v.clientIDs {
		payload, err := idtoken.Validate(ctx, token, audience)
		if err != nil {
			lastErr = err
			continue
		}

		email, _ := payload.Claims["email"].(string)
		verified, _ := payload.Claims["email_verified"].(bool)

		if payload.Subject == "" {
			return auth.GoogleIdentity{}, errors.New("google: token has no subject")
		}

		return auth.GoogleIdentity{
			Subject:       payload.Subject,
			Email:         email,
			EmailVerified: verified,
		}, nil
	}

	// The underlying error is not returned to a client; the caller maps this to a single
	// generic failure.
	return auth.GoogleIdentity{}, fmt.Errorf("google: token rejected: %w", lastErr)
}
