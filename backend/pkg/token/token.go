// Package token generates and hashes the opaque secrets the auth system hands out:
// refresh tokens and one-time verification codes.
//
// Both are stored HASHED. A database dump must not yield a working session or a live
// verification code, for the same reason it must not yield a password
// (ARCHITECTURE.md 18.2).
package token

import (
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/base64"
	"encoding/hex"
	"fmt"
	"math/big"
)

// NewOpaque returns a URL-safe random token with 256 bits of entropy.
//
// Used for refresh tokens, where the value is never shown to a person and length costs
// nothing.
func NewOpaque() (string, error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", fmt.Errorf("token: read random: %w", err)
	}
	return base64.RawURLEncoding.EncodeToString(b), nil
}

// NewNumericCode returns a zero-padded decimal code of the given length.
//
// Digits only, because a person reads this out of an email and types it on a phone
// keypad. The short alphabet is compensated for by a short expiry and a hard attempt
// limit, which is where the real protection comes from.
//
// crypto/rand, not math/rand: a predictable verification code is no verification at all.
func NewNumericCode(digits int) (string, error) {
	if digits < 4 || digits > 10 {
		return "", fmt.Errorf("token: unsupported code length %d", digits)
	}

	max := new(big.Int).Exp(big.NewInt(10), big.NewInt(int64(digits)), nil)
	n, err := rand.Int(rand.Reader, max)
	if err != nil {
		return "", fmt.Errorf("token: read random: %w", err)
	}
	return fmt.Sprintf("%0*d", digits, n), nil
}

// Hash returns the hex SHA-256 of a token.
//
// SHA-256 rather than Argon2id is deliberate here, and only here: these values are long
// random strings, not human-chosen passwords, so there is no dictionary to attack and a
// slow hash would only add latency to every request that presents one.
func Hash(value string) string {
	sum := sha256.Sum256([]byte(value))
	return hex.EncodeToString(sum[:])
}

// Equal compares two hashes in constant time.
func Equal(a, b string) bool {
	return subtle.ConstantTimeCompare([]byte(a), []byte(b)) == 1
}
