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
