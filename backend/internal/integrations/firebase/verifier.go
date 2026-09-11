// Package firebase verifies the ID tokens Firebase Authentication issues.
//
// This is the ONLY package that knows Firebase exists. It implements
// auth.GoogleTokenVerifier, an interface the auth module owns, so the service never learns
// which identity provider produced the token it is handed (ARCHITECTURE.md 7.1, ADR-006).
//
// Where Firebase sits in the picture. The app signs in with Google, hands the resulting
// credential to Firebase Authentication, and receives a Firebase ID token. That token is
// what reaches this backend. Firebase is the identity provider and nothing more: Voca
// users, sessions and every business rule stay in PostgreSQL behind this service, and a
// Firebase UID is never used as an application session.
//
// Verification happens SERVER-SIDE against Google's published keys. Trusting a token the
// app simply forwards, without checking its signature, issuer, audience and expiry, would
// let anyone sign in as anyone by crafting one (ARCHITECTURE.md 8.1).
//
// No service account key is needed or wanted. Verifying an ID token requires only the
// project ID and Google's public certificates, so there is no private key to store, leak
// or rotate.
package firebase

import (
	"context"
	"errors"
	"fmt"
	"strings"

	firebaseadmin "firebase.google.com/go/v4"
	firebaseauth "firebase.google.com/go/v4/auth"
	"google.golang.org/api/option"

	"github.com/samandar-hodiev/voca/backend/internal/auth"
)

// ErrNotConfigured means no Firebase project was supplied, so no token can be trusted.
var ErrNotConfigured = errors.New("firebase: no project ID configured")

// tokenVerifier is the part of the Firebase client this package uses. Declaring it makes
// the dependency testable without reaching Google.
type tokenVerifier interface {
	VerifyIDToken(ctx context.Context, token string) (*firebaseauth.Token, error)
}

// Verifier checks Firebase ID tokens.
type Verifier struct {
	projectID string
	client    tokenVerifier
}

// New builds a verifier for a project.
//
// An empty project ID is allowed and makes every verification fail closed, which is what
// lets the app show the button as unavailable rather than broken. A failure to build the
// client is treated the same way rather than stopping the service: sign-in by email must
// keep working when Google sign-in cannot.
func New(ctx context.Context, projectID string) *Verifier {
	projectID = strings.TrimSpace(projectID)
	if projectID == "" {
		return &Verifier{}
	}

	app, err := firebaseadmin.NewApp(ctx,
		&firebaseadmin.Config{ProjectID: projectID},
		// Verification needs no credentials, only the project ID and Google's public
		// certificates. Saying so explicitly stops the SDK hunting for a service account
		// that should not exist.
		option.WithoutAuthentication())
	if err != nil {
		return &Verifier{projectID: projectID}
	}

	client, err := app.Auth(ctx)
	if err != nil {
		return &Verifier{projectID: projectID}
	}

	return &Verifier{projectID: projectID, client: client}
}

// Configured reports whether Google sign-in can work at all.
func (v *Verifier) Configured() bool { return v.client != nil }

// Verify validates the token and returns the identity behind it.
//
// The SDK checks the signature against Google's rotating certificates, the issuer, the
// audience and the expiry. The audience matters most: a valid Firebase token issued for a
// DIFFERENT project would otherwise be accepted here.
func (v *Verifier) Verify(ctx context.Context, token string) (auth.GoogleIdentity, error) {
	if !v.Configured() {
		return auth.GoogleIdentity{}, ErrNotConfigured
	}

	decoded, err := v.client.VerifyIDToken(ctx, token)
	if err != nil {
		return auth.GoogleIdentity{}, fmt.Errorf("firebase: token rejected: %w", err)
	}
	if decoded.UID == "" {
		return auth.GoogleIdentity{}, errors.New("firebase: token has no subject")
	}

	return auth.GoogleIdentity{
		Subject:       decoded.UID,
		Email:         claimString(decoded.Claims, "email"),
		EmailVerified: claimBool(decoded.Claims, "email_verified"),
		DisplayName:   claimString(decoded.Claims, "name"),
		PhotoURL:      claimString(decoded.Claims, "picture"),
	}, nil
}

func claimString(claims map[string]any, key string) string {
	v, _ := claims[key].(string)
	return strings.TrimSpace(v)
}

func claimBool(claims map[string]any, key string) bool {
	v, _ := claims[key].(bool)
	return v
}
