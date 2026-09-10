// Package password hashes and verifies passwords with Argon2id.
//
// Argon2id is the current recommendation: it resists both GPU cracking and side-channel
// attacks, which is why it is preferred over bcrypt for new systems
// (ARCHITECTURE.md 18.2).
//
// A password is never logged, never returned, and never stored in any form but the hash
// produced here.
package password

import (
	"crypto/rand"
	"crypto/subtle"
	"encoding/base64"
	"errors"
	"fmt"
	"strings"

	"golang.org/x/crypto/argon2"
)

// Parameters. These are cost settings, not secrets, and they are stored in the encoded
// hash so an old hash stays verifiable after they are raised.
const (
	// 64 MiB. The main defence: memory cost is what makes parallel cracking expensive.
	memoryKiB = 64 * 1024
	// Passes over memory.
	iterations = 3
	// Lanes. Matching a typical server core count.
	parallelism = 2
	saltLength  = 16
	keyLength   = 32
)

// MinLength is the shortest password accepted. Length beats character-class rules: a
// long passphrase is both stronger and easier to remember than a short one padded with
// symbols.
const MinLength = 8

var (
	// ErrMismatch means the password does not match the hash. Callers must not tell a
	// client whether the address or the password was wrong.
	ErrMismatch = errors.New("password: mismatch")

	ErrInvalidHash = errors.New("password: malformed hash")
	ErrTooShort    = fmt.Errorf("password: must be at least %d characters", MinLength)
)

// Hash derives an encoded Argon2id hash.
func Hash(plain string) (string, error) {
	if len([]rune(plain)) < MinLength {
		return "", ErrTooShort
	}

	salt := make([]byte, saltLength)
	if _, err := rand.Read(salt); err != nil {
		return "", fmt.Errorf("password: read salt: %w", err)
	}

	key := argon2.IDKey([]byte(plain), salt, iterations, memoryKiB, parallelism, keyLength)

	// The standard PHC string. Self-describing, so raising the parameters later does not
	// invalidate existing hashes.
	return fmt.Sprintf(
		"$argon2id$v=%d$m=%d,t=%d,p=%d$%s$%s",
		argon2.Version, memoryKiB, iterations, parallelism,
		base64.RawStdEncoding.EncodeToString(salt),
		base64.RawStdEncoding.EncodeToString(key),
	), nil
}

// Verify reports whether plain matches encoded.
//
// Returns ErrMismatch for a wrong password and ErrInvalidHash for a corrupt record; the
// caller must collapse both into one client-facing message.
func Verify(plain, encoded string) error {
	parts := strings.Split(encoded, "$")
	if len(parts) != 6 || parts[1] != "argon2id" {
		return ErrInvalidHash
	}

	var version int
	if _, err := fmt.Sscanf(parts[2], "v=%d", &version); err != nil {
		return ErrInvalidHash
	}

	var memory uint32
	var time uint32
	var threads uint8
	if _, err := fmt.Sscanf(parts[3], "m=%d,t=%d,p=%d", &memory, &time, &threads); err != nil {
		return ErrInvalidHash
	}

	salt, err := base64.RawStdEncoding.DecodeString(parts[4])
	if err != nil {
		return ErrInvalidHash
	}
	want, err := base64.RawStdEncoding.DecodeString(parts[5])
	if err != nil {
		return ErrInvalidHash
	}

	got := argon2.IDKey([]byte(plain), salt, time, memory, threads, uint32(len(want)))

	// Constant time: a byte-by-byte compare leaks how much of the hash matched.
	if subtle.ConstantTimeCompare(got, want) != 1 {
		return ErrMismatch
	}
	return nil
}
