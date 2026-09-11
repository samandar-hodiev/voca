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

	// TemplateAccountExists is sent when somebody tries to create an account with an
	// address that already has one. It carries no code and no link that would let the
	// sender in, so it is safe to send to an address whoever typed it may not own.
	TemplateAccountExists EmailTemplate = "account_exists"

	// TemplateSignOutCode confirms a sign-out. It only ever goes to the address the
	// account already has.
	TemplateSignOutCode EmailTemplate = "sign_out_code"
)

// EmailProvider delivers transactional email.
type EmailProvider interface {
	Name() string
	Send(ctx context.Context, msg EmailMessage) error
}

// GoogleIdentity is what a verified identity token tells us about a person.
//
// Every field comes from the token's signed claims. Nothing here is taken from the request
// body: a client is free to send whatever name it likes, and believing it would let
// somebody sign in as one identity while presenting another's details.
type GoogleIdentity struct {
	Subject       string
	Email         string
	EmailVerified bool

	// DisplayName and PhotoURL are best-effort. A Google account usually has both, but a
	// token without them is still a valid sign-in.
	DisplayName string
	PhotoURL    string
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

// AvatarStore keeps profile pictures.
//
// The port is owned here so the service never learns whether the bytes end up on a local
// disk, in S3 or anywhere else. The MVP writes them to a directory; moving to object
// storage later is a new adapter and no change to this package (ARCHITECTURE.md 7.1,
// ADR-006).
type AvatarStore interface {
	// Put stores the image and returns the URL a client should use to fetch it.
	//
	// contentType is the caller's claim and must not be trusted on its own; an adapter is
	// expected to check the bytes themselves.
	Put(ctx context.Context, userID string, contentType string, data []byte) (string, error)

	// Remove deletes a previously stored image. Removing something that is not there is
	// not an error, so replacing an avatar never fails on the cleanup half.
	Remove(ctx context.Context, url string) error
}
