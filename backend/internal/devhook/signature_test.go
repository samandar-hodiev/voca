package devhook

import "testing"

const testSecret = "test-webhook-secret"

func TestVerifySignature_ValidSignatureIsAccepted(t *testing.T) {
	payload := []byte(`{"ref":"refs/heads/main"}`)
	sig := ComputeSignature(testSecret, payload)

	if !VerifySignature(testSecret, payload, sig) {
		t.Fatal("a signature produced with the same secret and payload must verify")
	}
}

func TestVerifySignature_TamperedPayloadIsRejected(t *testing.T) {
	original := []byte(`{"ref":"refs/heads/main"}`)
	sig := ComputeSignature(testSecret, original)

	tampered := []byte(`{"ref":"refs/heads/attacker"}`)
	if VerifySignature(testSecret, tampered, sig) {
		t.Fatal("changing the body after signing must invalidate the signature")
	}
}

func TestVerifySignature_WrongSecretIsRejected(t *testing.T) {
	payload := []byte(`{"ref":"refs/heads/main"}`)
	sig := ComputeSignature("some-other-secret", payload)

	if VerifySignature(testSecret, payload, sig) {
		t.Fatal("a signature made with a different secret must not verify")
	}
}

// An unconfigured service must fail CLOSED: with no secret, nothing is trusted.
func TestVerifySignature_EmptySecretRejectsEverything(t *testing.T) {
	payload := []byte(`{}`)
	if VerifySignature("", payload, ComputeSignature("", payload)) {
		t.Fatal("an empty secret must reject every request, even a self-consistent one")
	}
}

func TestVerifySignature_MalformedHeaders(t *testing.T) {
	payload := []byte(`{}`)
	valid := ComputeSignature(testSecret, payload)

	cases := map[string]string{
		"empty":            "",
		"missing prefix":   valid[len("sha256="):],
		"wrong algorithm":  "sha1=" + valid[len("sha256="):],
		"not hex":          "sha256=zzzznothex",
		"truncated digest": valid[:20],
		"prefix only":      "sha256=",
	}

	for name, header := range cases {
		t.Run(name, func(t *testing.T) {
			if VerifySignature(testSecret, payload, header) {
				t.Fatalf("malformed header %q must be rejected", header)
			}
		})
	}
}
