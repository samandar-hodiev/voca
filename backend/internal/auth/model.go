// Domain entities for identity and sessions.
//
// Plain Go structs expressing business concepts. Independent of transport, of storage row
// shapes, and of any provider payload (ARCHITECTURE.md 5.3).
package auth

import (
	"time"

	"github.com/google/uuid"
)

// Provider is how a person signs in.
type Provider string

const (
	ProviderEmail Provider = "email"
	ProviderApple Provider = "apple"
	ProviderGuest Provider = "guest"
)

// VerificationPurpose distinguishes the two one-time-code flows. They share a table and a
// security policy but must never be interchangeable: a code issued to confirm an address
// must not be usable to reset that address's password.
type VerificationPurpose string

const (
	PurposeSignup        VerificationPurpose = "signup"
	PurposePasswordReset VerificationPurpose = "password_reset"
	PurposeSignOut       VerificationPurpose = "sign_out"

	// PurposeDeleteAccount proves the person asking to delete an account owns its
	// mailbox. Kept apart from PurposeSignOut on purpose: a code issued to end a session
	// must never be usable to destroy the account behind it.
	PurposeDeleteAccount VerificationPurpose = "delete_account"
)

// User is an account.
type User struct {
	ID             uuid.UUID
	Provider       Provider
	ExternalAuthID *string
	Email          *string
	EmailVerified  bool
	Status         string
	CreatedAt      time.Time
}

// IsGuest reports whether this account has no credential yet.
func (u User) IsGuest() bool { return u.Provider == ProviderGuest }

// Profile is display identity.
type Profile struct {
	UserID    uuid.UUID
	FirstName *string
	LastName  *string
	Phone     *string
	AvatarURL *string
}

// Preferences holds the onboarding answers and learning settings.
//
// Levels and goals are stable identifiers, never localized display text: the label shown
// on screen can change with a translation, the stored value cannot.
type Preferences struct {
	UserID                uuid.UUID
	CEFRLevel             *string
	LearningGoal          *string
	DailyGoalWords        int
	UILanguage            string
	LearningLanguage      string
	Accent                string
	Timezone              string
	OnboardingCompletedAt *time.Time
}

// ValidLevels and ValidGoals mirror the CHECK constraints in the schema. Validating in
// the service as well means a bad value is a 400 with a useful message rather than a 500
// from the database.
var ValidLevels = map[string]bool{"A1": true, "A2": true, "B1": true, "B2": true, "C1": true}

var ValidGoals = map[string]bool{
	"pronunciation": true, "confidence": true, "ielts": true,
	"vocabulary": true, "work": true, "everyday": true,
}

// Session is the token pair handed to a client after authentication.
type Session struct {
	User         User
	AccessToken  string
	RefreshToken string
	ExpiresIn    int
}

// Verification is a live one-time code challenge.
type Verification struct {
	ID          uuid.UUID
	Email       string
	Purpose     VerificationPurpose
	Attempts    int
	MaxAttempts int
	ExpiresAt   time.Time
	ConsumedAt  *time.Time
	VerifiedAt  *time.Time
	CreatedAt   time.Time
}

// Expired reports whether the challenge is past its lifetime.
func (v Verification) Expired(now time.Time) bool { return now.After(v.ExpiresAt) }

// Exhausted reports whether too many wrong codes have been tried.
func (v Verification) Exhausted() bool { return v.Attempts >= v.MaxAttempts }

// Usable reports whether this challenge can still accept a code.
func (v Verification) Usable(now time.Time) bool {
	return v.ConsumedAt == nil && !v.Expired(now) && !v.Exhausted()
}
