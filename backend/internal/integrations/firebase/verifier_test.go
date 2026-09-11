package firebase

import (
	"context"
	"errors"
	"testing"

	firebaseauth "firebase.google.com/go/v4/auth"
)

type stubVerifier struct {
	token *firebaseauth.Token
	err   error
}

func (s stubVerifier) VerifyIDToken(context.Context, string) (*firebaseauth.Token, error) {
	return s.token, s.err
}

// No project means no token can be trusted, and the app is told the method is unavailable
// rather than being shown a button that cannot work.
func TestNotConfiguredWithoutAProject(t *testing.T) {
	v := New(context.Background(), "   ")
	if v.Configured() {
		t.Fatal("a blank project ID must not count as configured")
	}
	if _, err := v.Verify(context.Background(), "anything"); !errors.Is(err, ErrNotConfigured) {
		t.Fatalf("got %v, want ErrNotConfigured", err)
	}
}

func TestConfiguredWithAProject(t *testing.T) {
	v := New(context.Background(), "voca-508308")
	if !v.Configured() {
		t.Fatal("a project ID should produce a working verifier")
	}
}

func TestVerifyReturnsTheSignedClaims(t *testing.T) {
	v := &Verifier{
		projectID: "voca-508308",
		client: stubVerifier{token: &firebaseauth.Token{
			UID: "firebase-uid-1",
			Claims: map[string]any{
				"email":          "learner@example.com",
				"email_verified": true,
				"name":           "Samandar Xodiev",
				"picture":        "https://example.com/p.jpg",
			},
		}},
	}

	identity, err := v.Verify(context.Background(), "token")
	if err != nil {
		t.Fatalf("Verify: %v", err)
	}
	if identity.Subject != "firebase-uid-1" {
		t.Errorf("Subject = %q", identity.Subject)
	}
	if identity.Email != "learner@example.com" || !identity.EmailVerified {
		t.Errorf("email = %q verified = %v", identity.Email, identity.EmailVerified)
	}
	if identity.DisplayName != "Samandar Xodiev" {
		t.Errorf("DisplayName = %q", identity.DisplayName)
	}
	if identity.PhotoURL != "https://example.com/p.jpg" {
		t.Errorf("PhotoURL = %q", identity.PhotoURL)
	}
}

// A token the SDK refuses must not become an identity, whatever else it contains.
func TestVerifyRejectsAnInvalidToken(t *testing.T) {
	v := &Verifier{
		projectID: "voca-508308",
		client:    stubVerifier{err: errors.New("signature is invalid")},
	}

	if _, err := v.Verify(context.Background(), "forged"); err == nil {
		t.Fatal("expected a refused token to return an error")
	}
}

// Without a subject there is nothing to attach an account to.
func TestVerifyRejectsATokenWithNoSubject(t *testing.T) {
	v := &Verifier{
		projectID: "voca-508308",
		client: stubVerifier{token: &firebaseauth.Token{
			Claims: map[string]any{"email": "a@b.com"},
		}},
	}

	if _, err := v.Verify(context.Background(), "token"); err == nil {
		t.Fatal("expected a token with no subject to be refused")
	}
}

// Missing optional claims are normal and must not fail the sign-in.
func TestVerifyToleratesMissingOptionalClaims(t *testing.T) {
	v := &Verifier{
		projectID: "voca-508308",
		client: stubVerifier{token: &firebaseauth.Token{
			UID:    "uid",
			Claims: map[string]any{"email": "a@b.com", "email_verified": true},
		}},
	}

	identity, err := v.Verify(context.Background(), "token")
	if err != nil {
		t.Fatalf("Verify: %v", err)
	}
	if identity.DisplayName != "" || identity.PhotoURL != "" {
		t.Errorf("expected empty optional claims, got %q and %q",
			identity.DisplayName, identity.PhotoURL)
	}
}
