// Package jwt issues and verifies short-lived access tokens.
//
// HS256 with a single shared secret is enough while one service both issues and verifies.
// When a second service must verify independently, this moves to RS256; the mobile client
// is unaffected because it never inspects the signature (ARCHITECTURE.md 8.2).
//
// Claims are deliberately minimal: the subject and the timestamps. Entitlement is NOT a
// claim, because a fifteen-minute-old claim would let a cancelled subscription keep
// working and make a fresh purchase feel broken (ARCHITECTURE.md 9.4).
package jwt

import (
	"errors"
	"fmt"
	"time"

	jwtlib "github.com/golang-jwt/jwt/v5"
)

var (
	// ErrInvalid covers every reason a token was not accepted. Callers must not tell a
	// client which reason applied: that helps craft one that is accepted.
	ErrInvalid = errors.New("jwt: invalid token")

	ErrEmptySecret = errors.New("jwt: signing secret must not be empty")
)

// Issuer signs and verifies access tokens.
type Issuer struct {
	secret []byte
	ttl    time.Duration
}

// NewIssuer builds an issuer. An empty secret is refused rather than defaulted: a service
// that signs with a predictable key is worse than one that will not start.
func NewIssuer(secret string, ttl time.Duration) (*Issuer, error) {
	if secret == "" {
		return nil, ErrEmptySecret
	}
	return &Issuer{secret: []byte(secret), ttl: ttl}, nil
}

// TTL is how long a freshly issued token lasts.
func (i *Issuer) TTL() time.Duration { return i.ttl }

// Issue returns a signed access token for subject.
func (i *Issuer) Issue(subject string) (string, error) {
	now := time.Now()
	token := jwtlib.NewWithClaims(jwtlib.SigningMethodHS256, jwtlib.RegisteredClaims{
		Subject:   subject,
		IssuedAt:  jwtlib.NewNumericDate(now),
		ExpiresAt: jwtlib.NewNumericDate(now.Add(i.ttl)),
		ID:        subject + ":" + now.Format(time.RFC3339Nano),
	})

	signed, err := token.SignedString(i.secret)
	if err != nil {
		return "", fmt.Errorf("jwt: sign: %w", err)
	}
	return signed, nil
}

// Verify returns the subject of a valid token.
func (i *Issuer) Verify(raw string) (string, error) {
	claims := &jwtlib.RegisteredClaims{}

	// The signing method is pinned. Without this check a token could claim alg=none, or
	// alg=RS256 with our secret used as a public key: the classic algorithm-confusion
	// attack.
	_, err := jwtlib.ParseWithClaims(raw, claims, func(t *jwtlib.Token) (any, error) {
		if _, ok := t.Method.(*jwtlib.SigningMethodHMAC); !ok {
			return nil, ErrInvalid
		}
		return i.secret, nil
	}, jwtlib.WithValidMethods([]string{"HS256"}))

	if err != nil || claims.Subject == "" {
		return "", ErrInvalid
	}
	return claims.Subject, nil
}
