// GitHub webhook signature verification.
//
// GitHub signs each delivery with HMAC-SHA256 over the RAW request body, using the shared
// secret configured on the webhook, and sends it as:
//
//	X-Hub-Signature-256: sha256=<hex digest>
//
// The comparison is constant time. The secret comes from GITHUB_WEBHOOK_SECRET and is
// never logged or echoed (ARCHITECTURE.md 18.2).
package devhook

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"strings"
)

const signaturePrefix = "sha256="

// VerifySignature reports whether header is a valid signature of payload under secret.
//
// It returns false for an empty secret, so a service started WITHOUT a configured secret
// rejects every webhook instead of accepting unverified ones. That is the safe default:
// failing closed rather than open.
func VerifySignature(secret string, payload []byte, header string) bool {
	if secret == "" || header == "" {
		return false
	}
	if !strings.HasPrefix(header, signaturePrefix) {
		return false
	}

	want, err := hex.DecodeString(strings.TrimPrefix(header, signaturePrefix))
	if err != nil {
		return false
	}

	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write(payload)

	// hmac.Equal is constant time, which matters: a byte-by-byte compare would leak the
	// expected digest to an attacker measuring response times.
	return hmac.Equal(want, mac.Sum(nil))
}

// ComputeSignature produces the header value GitHub would send for this payload.
// Used by tests and by the local verification script; not used on the request path.
func ComputeSignature(secret string, payload []byte) string {
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write(payload)
	return signaturePrefix + hex.EncodeToString(mac.Sum(nil))
}
