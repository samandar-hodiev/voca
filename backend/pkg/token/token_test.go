package token

import (
	"regexp"
	"testing"
)

func TestNewOpaque_IsUniqueAndUrlSafe(t *testing.T) {
	safe := regexp.MustCompile(`^[A-Za-z0-9_-]+$`)
	seen := make(map[string]bool, 200)

	for i := 0; i < 200; i++ {
		v, err := NewOpaque()
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if !safe.MatchString(v) {
			t.Fatalf("token is not URL-safe: %q", v)
		}
		if seen[v] {
			t.Fatal("tokens must not repeat")
		}
		seen[v] = true
	}
}

func TestNewNumericCode_ShapeAndRange(t *testing.T) {
	digits := regexp.MustCompile(`^[0-9]{6}$`)

	for i := 0; i < 200; i++ {
		code, err := NewNumericCode(6)
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		// Zero padding matters: 000123 is a valid code and must not become 123.
		if !digits.MatchString(code) {
			t.Fatalf("code must be exactly six digits, got %q", code)
		}
	}
}

func TestNewNumericCode_RejectsUnsupportedLengths(t *testing.T) {
	for _, n := range []int{0, 3, 11} {
		if _, err := NewNumericCode(n); err == nil {
			t.Errorf("length %d must be rejected", n)
		}
	}
}

// Codes must not be predictable. This does not prove randomness, but it does catch a
// constant or a low-entropy source.
func TestNewNumericCode_IsNotConstant(t *testing.T) {
	first, _ := NewNumericCode(6)
	for i := 0; i < 50; i++ {
		if v, _ := NewNumericCode(6); v != first {
			return
		}
	}
	t.Fatal("50 codes in a row were identical")
}

func TestHash_IsStableAndHidesTheValue(t *testing.T) {
	const secret = "a-refresh-token-value"

	h := Hash(secret)
	if h != Hash(secret) {
		t.Fatal("hashing must be deterministic")
	}
	if h == secret {
		t.Fatal("the hash must differ from the value")
	}
	if len(h) != 64 {
		t.Fatalf("expected a 64-character hex digest, got %d", len(h))
	}
}

func TestEqual(t *testing.T) {
	h := Hash("value")
	if !Equal(h, Hash("value")) {
		t.Error("identical hashes must compare equal")
	}
	if Equal(h, Hash("other")) {
		t.Error("different hashes must not compare equal")
	}
}
