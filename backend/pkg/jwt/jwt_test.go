package jwt

import (
	"errors"
	"strings"
	"testing"
	"time"
)

func newIssuer(t *testing.T, ttl time.Duration) *Issuer {
	t.Helper()
	i, err := NewIssuer("a-test-signing-secret-value", ttl)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	return i
}

func TestIssueAndVerify(t *testing.T) {
	i := newIssuer(t, time.Minute)

	token, err := i.Issue("user-123")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	subject, err := i.Verify(token)
	if err != nil {
		t.Fatalf("a freshly issued token must verify: %v", err)
	}
	if subject != "user-123" {
		t.Errorf("subject = %q, want user-123", subject)
	}
}

func TestVerify_RejectsExpiredToken(t *testing.T) {
	i := newIssuer(t, -time.Second) // already expired

	token, _ := i.Issue("user-123")

	if _, err := i.Verify(token); !errors.Is(err, ErrInvalid) {
		t.Fatalf("an expired token must be rejected, got %v", err)
	}
}

func TestVerify_RejectsTokenSignedWithAnotherSecret(t *testing.T) {
	other, _ := NewIssuer("a-different-secret-entirely", time.Minute)
	token, _ := other.Issue("user-123")

	if _, err := newIssuer(t, time.Minute).Verify(token); !errors.Is(err, ErrInvalid) {
		t.Fatalf("a token signed elsewhere must be rejected, got %v", err)
	}
}

// alg=none is the oldest JWT attack: an unsigned token that claims it needs no signature.
func TestVerify_RejectsUnsignedToken(t *testing.T) {
	// {"alg":"none","typ":"JWT"}.{"sub":"attacker"}. with an empty signature
	const unsigned = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0." +
		"eyJzdWIiOiJhdHRhY2tlciJ9."

	if _, err := newIssuer(t, time.Minute).Verify(unsigned); !errors.Is(err, ErrInvalid) {
		t.Fatalf("alg=none must be rejected, got %v", err)
	}
}

func TestVerify_RejectsGarbage(t *testing.T) {
	i := newIssuer(t, time.Minute)
	for _, raw := range []string{"", "not-a-token", "a.b.c", strings.Repeat("x", 200)} {
		if _, err := i.Verify(raw); !errors.Is(err, ErrInvalid) {
			t.Errorf("%q must be rejected, got %v", raw, err)
		}
	}
}

// A service that signs with a predictable key is worse than one that refuses to start.
func TestNewIssuer_RefusesEmptySecret(t *testing.T) {
	if _, err := NewIssuer("", time.Minute); !errors.Is(err, ErrEmptySecret) {
		t.Fatalf("an empty secret must be refused, got %v", err)
	}
}

// The token must not carry anything beyond identity: entitlement in a claim would go
// stale (ARCHITECTURE.md 9.4).
func TestIssue_CarriesNoEntitlementClaims(t *testing.T) {
	token, _ := newIssuer(t, time.Minute).Issue("user-123")

	for _, forbidden := range []string{"premium", "tier", "subscription", "role"} {
		if strings.Contains(strings.ToLower(token), forbidden) {
			t.Errorf("token must not carry %q", forbidden)
		}
	}
}
