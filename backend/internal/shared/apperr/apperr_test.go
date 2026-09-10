package apperr

import (
	"errors"
	"net/http"
	"testing"
)

func TestConstructorsFixTheirStatusCode(t *testing.T) {
	cases := []struct {
		name string
		err  *AppError
		code Code
		want int
	}{
		{"validation", Validation("bad"), CodeValidation, http.StatusBadRequest},
		{"unauthenticated", Unauthenticated("no"), CodeUnauthenticated, http.StatusUnauthorized},
		{"forbidden", Forbidden("no"), CodeForbidden, http.StatusForbidden},
		{"not found", NotFound("gone"), CodeNotFound, http.StatusNotFound},
		{"conflict", Conflict("dup"), CodeConflict, http.StatusConflict},
		{"rate limited", RateLimited("slow"), CodeRateLimited, http.StatusTooManyRequests},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			if c.err.Code != c.code {
				t.Errorf("Code = %q, want %q", c.err.Code, c.code)
			}
			if c.err.HTTPStatus != c.want {
				t.Errorf("HTTPStatus = %d, want %d", c.err.HTTPStatus, c.want)
			}
		})
	}
}

// An unknown error must become a 500 with a generic message. Anything else risks
// leaking a driver message or a file path to a client.
func TestFrom_UnknownErrorBecomesInternal(t *testing.T) {
	got := From(errors.New("pq: duplicate key value violates constraint users_email_key"))

	if got.Code != CodeInternal {
		t.Errorf("Code = %q, want %q", got.Code, CodeInternal)
	}
	if got.HTTPStatus != http.StatusInternalServerError {
		t.Errorf("status = %d, want 500", got.HTTPStatus)
	}
	if got.Message != "An unexpected error occurred." {
		t.Errorf("client message must be generic, got %q", got.Message)
	}
}

// The internal cause must remain reachable for logging while staying out of Message.
func TestInternal_KeepsCauseForLoggingOnly(t *testing.T) {
	cause := errors.New("connection refused")
	got := Internal(cause)

	if !errors.Is(got, cause) {
		t.Error("the wrapped cause must be reachable via errors.Is for logging")
	}
	if got.Message == cause.Error() {
		t.Error("the internal cause must not become the client-facing message")
	}
}

func TestFrom_PreservesAnExistingAppError(t *testing.T) {
	original := NotFound("word not found")
	if got := From(original); got != original {
		t.Error("From must return the same AppError, not rewrap it")
	}
}

func TestFrom_NilIsNil(t *testing.T) {
	if From(nil) != nil {
		t.Error("From(nil) must be nil")
	}
}

// USAGE_LIMIT_REACHED and PREMIUM_REQUIRED drive different screens, so they must never
// collapse into one code (ARCHITECTURE.md 19.2).
func TestQuotaAndPlanCodesAreDistinct(t *testing.T) {
	if CodeUsageLimit == CodePremiumRequired {
		t.Fatal("quota and plan errors must remain distinct codes")
	}
}

func TestWithDetailsAndWrap(t *testing.T) {
	cause := errors.New("boom")
	e := Validation("bad audio").WithDetails(map[string]any{"max_ms": 15000}).Wrap(cause)

	if e.Details["max_ms"] != 15000 {
		t.Errorf("details not attached: %v", e.Details)
	}
	if !errors.Is(e, cause) {
		t.Error("Wrap must preserve the cause")
	}
}
