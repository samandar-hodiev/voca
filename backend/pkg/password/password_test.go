package password

import (
	"errors"
	"strings"
	"testing"
)

func TestHashAndVerify(t *testing.T) {
	const plain = "correct horse battery"

	encoded, err := Hash(plain)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if err := Verify(plain, encoded); err != nil {
		t.Fatalf("the correct password must verify: %v", err)
	}
}

func TestVerify_WrongPasswordIsRejected(t *testing.T) {
	encoded, _ := Hash("correct horse battery")

	if err := Verify("Correct horse battery", encoded); !errors.Is(err, ErrMismatch) {
		t.Fatalf("expected ErrMismatch, got %v", err)
	}
}

// The plaintext must not be recoverable or even visible in the stored value.
func TestHash_DoesNotContainThePassword(t *testing.T) {
	const plain = "supersecretvalue"

	encoded, _ := Hash(plain)

	if strings.Contains(encoded, plain) {
		t.Fatal("the encoded hash must not contain the password")
	}
}

// A per-password salt means two people with the same password get different hashes, so a
// leaked table cannot be cracked once and reused.
func TestHash_IsSaltedPerCall(t *testing.T) {
	a, _ := Hash("same password")
	b, _ := Hash("same password")

	if a == b {
		t.Fatal("hashing the same password twice must produce different values")
	}
	if err := Verify("same password", a); err != nil {
		t.Error("first hash must verify")
	}
	if err := Verify("same password", b); err != nil {
		t.Error("second hash must verify")
	}
}

func TestHash_RejectsShortPasswords(t *testing.T) {
	if _, err := Hash("short12"); !errors.Is(err, ErrTooShort) {
		t.Fatalf("7 characters must be rejected, got %v", err)
	}
	if _, err := Hash("exactly8"); err != nil {
		t.Fatalf("8 characters must be accepted, got %v", err)
	}
}

// Length is counted in runes: an 8-character Uzbek or Cyrillic password is 8 characters,
// not however many bytes it happens to occupy.
func TestHash_CountsRunesNotBytes(t *testing.T) {
	if _, err := Hash("парольча"); err != nil {
		t.Fatalf("an 8-rune password must be accepted, got %v", err)
	}
}

func TestVerify_MalformedHash(t *testing.T) {
	for name, encoded := range map[string]string{
		"empty":          "",
		"not argon":      "$bcrypt$v=19$m=1,t=1,p=1$c2FsdA$aGFzaA",
		"missing fields": "$argon2id$v=19$m=65536",
		"bad base64":     "$argon2id$v=19$m=65536,t=3,p=2$!!!$!!!",
	} {
		t.Run(name, func(t *testing.T) {
			if err := Verify("anything", encoded); !errors.Is(err, ErrInvalidHash) {
				t.Errorf("expected ErrInvalidHash, got %v", err)
			}
		})
	}
}
