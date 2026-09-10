// Outbound ports the auth module depends on.
//
// The consumer owns these interfaces, not the vendor. An email provider is replaced by
// writing an adapter, not by editing the verification service (ARCHITECTURE.md 7.1,
// ADR-006).
package auth

import "context"

// EmailMessage is a provider-neutral message.
//
// It carries a template identifier and parameters rather than rendered HTML, so the
// wording lives in one place and a second UI language does not mean a second code path.
type EmailMessage struct {
	To       string
	Template EmailTemplate
	Params   map[string]string
}

// EmailTemplate names a message the product sends.
type EmailTemplate string

const (
	TemplateSignupCode        EmailTemplate = "signup_code"
	TemplatePasswordResetCode EmailTemplate = "password_reset_code"
)

// EmailProvider delivers transactional email.
type EmailProvider interface {
	Name() string
	Send(ctx context.Context, msg EmailMessage) error
}

// GoogleIdentity is what a verified Google token tells us about a person.
type GoogleIdentity struct {
	Subject       string
	Email         string
	EmailVerified bool
}

// GoogleTokenVerifier checks an ID token issued by Google.
//
// The port is owned here, not by the vendor package, so the service never imports a
// Google type and a test never needs the network (ARCHITECTURE.md 7.1, ADR-006).
type GoogleTokenVerifier interface {
	// Verify returns the identity behind idToken, or an error if it is not a valid token
	// issued to this application.
	Verify(ctx context.Context, idToken string) (GoogleIdentity, error)
}
