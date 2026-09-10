// Business logic for identity, verification and sessions.
//
// This is the module's public surface. Every rule that protects an account lives here,
// never in a handler and never in a client (ARCHITECTURE.md 5.3, 5.5).
package auth

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"net/mail"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/samandar-hodiev/voca/backend/internal/shared/apperr"
	"github.com/samandar-hodiev/voca/backend/pkg/jwt"
	"github.com/samandar-hodiev/voca/backend/pkg/password"
	"github.com/samandar-hodiev/voca/backend/pkg/token"
)

// Policy holds the security settings. They are configuration, not constants, so they can
// be tuned without a release.
type Policy struct {
	CodeLength        int
	CodeTTL           time.Duration
	CodeMaxAttempts   int
	ResendWindow      time.Duration
	ResendMaxInWindow int
	RefreshTTL        time.Duration
}

// DefaultPolicy is deliberately strict.
//
// A six-digit code has only a million possibilities, so the protection comes from the
// short life and the hard attempt cap, not from the alphabet.
func DefaultPolicy() Policy {
	return Policy{
		CodeLength:        6,
		CodeTTL:           10 * time.Minute,
		CodeMaxAttempts:   5,
		ResendWindow:      15 * time.Minute,
		ResendMaxInWindow: 5,
		RefreshTTL:        60 * 24 * time.Hour,
	}
}

// Service implements the authentication use cases.
type Service struct {
	repo   Repository
	issuer *jwt.Issuer
	email  EmailProvider
	google GoogleTokenVerifier
	policy Policy
	log    *slog.Logger
}

// NewService builds the service. A nil google verifier is allowed: Google sign-in then
// reports itself unavailable rather than the service refusing to start.
func NewService(repo Repository, issuer *jwt.Issuer, emailProvider EmailProvider,
	google GoogleTokenVerifier, policy Policy, log *slog.Logger) *Service {
	return &Service{
		repo: repo, issuer: issuer, email: emailProvider,
		google: google, policy: policy, log: log,
	}
}

// ---------------------------------------------------------------------------
// Email verification
// ---------------------------------------------------------------------------

// StartEmailVerification issues a one-time code for signing up.
//
// It returns success even when the address already has an account. Answering differently
// would turn this endpoint into a way to discover who is registered.
func (s *Service) StartEmailVerification(ctx context.Context, rawEmail string) error {
	email, err := normalizeEmail(rawEmail)
	if err != nil {
		return err
	}

	if _, err := s.repo.UserByEmail(ctx, email); err == nil {
		// Already registered. Send nothing, say nothing, and log it so the pattern is
		// still visible to us.
		s.log.Info("signup_code_suppressed_existing_account")
		return nil
	} else if !errors.Is(err, ErrNotFound) {
		return apperr.Internal(err)
	}

	return s.issueCode(ctx, email, PurposeSignup, TemplateSignupCode)
}

// StartPasswordReset issues a one-time code for setting a new password.
//
// Also silent about whether the address exists, for the same reason.
func (s *Service) StartPasswordReset(ctx context.Context, rawEmail string) error {
	email, err := normalizeEmail(rawEmail)
	if err != nil {
		return err
	}

	if _, err := s.repo.UserByEmail(ctx, email); err != nil {
		if errors.Is(err, ErrNotFound) {
			s.log.Info("reset_code_suppressed_unknown_account")
			return nil
		}
		return apperr.Internal(err)
	}

	return s.issueCode(ctx, email, PurposePasswordReset, TemplatePasswordResetCode)
}

// issueCode generates, stores and sends a code.
func (s *Service) issueCode(ctx context.Context, email string,
	purpose VerificationPurpose, template EmailTemplate) error {

	recent, err := s.repo.CountRecentVerifications(ctx, email, purpose, s.policy.ResendWindow)
	if err != nil {
		return apperr.Internal(err)
	}
	if recent >= s.policy.ResendMaxInWindow {
		return apperr.New(apperr.CodeTooManyRequests, http.StatusTooManyRequests,
			"Too many requests. Please wait before trying again.")
	}

	code, err := token.NewNumericCode(s.policy.CodeLength)
	if err != nil {
		return apperr.Internal(err)
	}

	if _, err := s.repo.CreateVerification(ctx, email, purpose, token.Hash(code),
		s.policy.CodeTTL, s.policy.CodeMaxAttempts); err != nil {
		return apperr.Internal(err)
	}

	// The code exists in exactly two places: this variable and the recipient's inbox. It
	// is never logged and never returned (ARCHITECTURE.md 18.4).
	if err := s.email.Send(ctx, EmailMessage{
		To:       email,
		Template: template,
		Params:   map[string]string{"code": code},
	}); err != nil {
		s.log.Error("verification_email_failed", slog.String("error", err.Error()))
		return apperr.New(apperr.CodeProviderUnavailable, http.StatusServiceUnavailable,
			"We could not send the email. Please try again.")
	}
	return nil
}

// VerifyCode checks a submitted code against the newest live challenge.
func (s *Service) VerifyCode(ctx context.Context, rawEmail string,
	purpose VerificationPurpose, code string) error {

	email, err := normalizeEmail(rawEmail)
	if err != nil {
		return err
	}

	v, err := s.repo.LatestVerification(ctx, email, purpose)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			return invalidCodeError()
		}
		return apperr.Internal(err)
	}

	now := time.Now()
	switch {
	case v.ConsumedAt != nil:
		return invalidCodeError()
	case v.Expired(now):
		return apperr.New(apperr.CodeCodeExpired, http.StatusBadRequest,
			"That code has expired. Request a new one.")
	case v.Exhausted():
		return apperr.New(apperr.CodeTooManyAttempts, http.StatusTooManyRequests,
			"Too many incorrect attempts. Request a new code.")
	}

	stored, err := s.repo.VerificationCodeHash(ctx, v.ID)
	if err != nil {
		return apperr.Internal(err)
	}

	if !token.Equal(stored, token.Hash(code)) {
		// The attempt is counted BEFORE the failure is reported, so a client that gives
		// up early still leaves the counter raised.
		if err := s.repo.RecordVerificationAttempt(ctx, v.ID); err != nil {
			return apperr.Internal(err)
		}
		return invalidCodeError()
	}

	if err := s.repo.MarkVerified(ctx, v.ID); err != nil {
		return apperr.Internal(err)
	}
	return nil
}

// invalidCodeError is one message for every wrong-code case, so a caller cannot learn
// whether an address has a live challenge.
func invalidCodeError() *apperr.AppError {
	return apperr.New(apperr.CodeInvalidCode, http.StatusBadRequest,
		"That code is not correct.")
}

// ---------------------------------------------------------------------------
// Registration and sessions
// ---------------------------------------------------------------------------

// RegisterInput carries everything account creation needs.
type RegisterInput struct {
	Email     string
	Password  string
	FirstName string
	LastName  string
	Phone     *string
	AvatarURL *string

	// Onboarding answers, carried through so the first screen after sign-up already knows
	// the person's level rather than asking twice.
	CEFRLevel      *string
	LearningGoal   *string
	DailyGoalWords *int
	Timezone       *string
}

// Register creates a verified account and returns a session.
//
// The address must already have passed VerifyCode: registration does not re-check a code,
// it checks that one was checked.
func (s *Service) Register(ctx context.Context, in RegisterInput) (Session, error) {
	email, err := normalizeEmail(in.Email)
	if err != nil {
		return Session{}, err
	}

	if strings.TrimSpace(in.FirstName) == "" || strings.TrimSpace(in.LastName) == "" {
		return Session{}, apperr.Validation("First name and last name are required.")
	}
	if err := validateLevelAndGoal(in.CEFRLevel, in.LearningGoal); err != nil {
		return Session{}, err
	}

	v, err := s.repo.LatestVerification(ctx, email, PurposeSignup)
	if err != nil || v.VerifiedAt == nil || v.ConsumedAt != nil || v.Expired(time.Now()) {
		return Session{}, apperr.New(apperr.CodeEmailNotVerified, http.StatusForbidden,
			"Verify your email address first.")
	}

	if _, err := s.repo.UserByEmail(ctx, email); err == nil {
		return Session{}, apperr.New(apperr.CodeEmailAlreadyExists, http.StatusConflict,
			"An account with this email already exists.")
	} else if !errors.Is(err, ErrNotFound) {
		return Session{}, apperr.Internal(err)
	}

	hash, err := password.Hash(in.Password)
	if err != nil {
		if errors.Is(err, password.ErrTooShort) {
			return Session{}, apperr.New(apperr.CodeInvalidPassword, http.StatusBadRequest,
				fmt.Sprintf("Password must be at least %d characters.", password.MinLength))
		}
		return Session{}, apperr.Internal(err)
	}

	// User, profile and preferences are written together. A half-created account could
	// neither log in nor be created again, because the address would already be taken.
	user, err := s.repo.CreateUserTx(ctx, func(tx pgx.Tx) (User, error) {
		var u User
		if err := tx.QueryRow(ctx,
			`INSERT INTO users (auth_provider, email, email_verified, password_hash)
			 VALUES ('email', $1, true, $2)
			 RETURNING `+userColumns, email, hash).
			Scan(&u.ID, &u.Provider, &u.ExternalAuthID, &u.Email,
				&u.EmailVerified, &u.Status, &u.CreatedAt); err != nil {
			return User{}, fmt.Errorf("auth: insert user: %w", err)
		}

		if _, err := tx.Exec(ctx,
			`INSERT INTO profiles (user_id, first_name, last_name, phone, avatar_url)
			 VALUES ($1, $2, $3, $4, $5)`,
			u.ID, in.FirstName, in.LastName, in.Phone, in.AvatarURL); err != nil {
			return User{}, fmt.Errorf("auth: insert profile: %w", err)
		}

		daily := 10
		if in.DailyGoalWords != nil {
			daily = *in.DailyGoalWords
		}
		tz := "Asia/Tashkent"
		if in.Timezone != nil && *in.Timezone != "" {
			tz = *in.Timezone
		}
		if _, err := tx.Exec(ctx,
			`INSERT INTO user_preferences
			   (user_id, cefr_level, learning_goal, daily_goal_words, timezone,
			    onboarding_completed_at)
			 VALUES ($1, $2, $3, $4, $5, now())`,
			u.ID, in.CEFRLevel, in.LearningGoal, daily, tz); err != nil {
			return User{}, fmt.Errorf("auth: insert preferences: %w", err)
		}
		return u, nil
	})
	if err != nil {
		return Session{}, apperr.Internal(err)
	}

	if err := s.repo.ConsumeVerification(ctx, v.ID); err != nil {
		s.log.Warn("verification_not_consumed", slog.String("error", err.Error()))
	}

	return s.newSession(ctx, user, nil)
}

// Login authenticates with an email address and a password.
func (s *Service) Login(ctx context.Context, rawEmail, plain string) (Session, error) {
	email, err := normalizeEmail(rawEmail)
	if err != nil {
		// Even a malformed address gets the generic answer here: the login endpoint must
		// not become a way to test which addresses exist.
		return Session{}, invalidCredentials()
	}

	user, err := s.repo.UserByEmail(ctx, email)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			// Hash anyway, so a missing account and a wrong password take the same time.
			_, _ = password.Hash("timing-equalizer-value")
			return Session{}, invalidCredentials()
		}
		return Session{}, apperr.Internal(err)
	}

	hash, err := s.repo.PasswordHash(ctx, user.ID)
	if err != nil {
		return Session{}, invalidCredentials()
	}
	if err := password.Verify(plain, hash); err != nil {
		return Session{}, invalidCredentials()
	}

	if err := s.repo.TouchLastLogin(ctx, user.ID); err != nil {
		s.log.Warn("last_login_not_recorded", slog.String("error", err.Error()))
	}
	return s.newSession(ctx, user, nil)
}

// invalidCredentials is one answer for a wrong address and a wrong password alike.
func invalidCredentials() *apperr.AppError {
	return apperr.New(apperr.CodeInvalidCredentials, http.StatusUnauthorized,
		"Email or password is incorrect.")
}

// CreateGuest opens an anonymous session.
//
// A guest is a full user row with no credential, so upgrading later is an UPDATE rather
// than a migration of their practice history onto a different account.
func (s *Service) CreateGuest(ctx context.Context, in RegisterInput) (Session, error) {
	if err := validateLevelAndGoal(in.CEFRLevel, in.LearningGoal); err != nil {
		return Session{}, err
	}

	user, err := s.repo.CreateUserTx(ctx, func(tx pgx.Tx) (User, error) {
		var u User
		if err := tx.QueryRow(ctx,
			`INSERT INTO users (auth_provider) VALUES ('guest')
			 RETURNING `+userColumns).
			Scan(&u.ID, &u.Provider, &u.ExternalAuthID, &u.Email,
				&u.EmailVerified, &u.Status, &u.CreatedAt); err != nil {
			return User{}, fmt.Errorf("auth: insert guest: %w", err)
		}
		if _, err := tx.Exec(ctx, `INSERT INTO profiles (user_id) VALUES ($1)`, u.ID); err != nil {
			return User{}, fmt.Errorf("auth: insert guest profile: %w", err)
		}

		daily := 10
		if in.DailyGoalWords != nil {
			daily = *in.DailyGoalWords
		}
		if _, err := tx.Exec(ctx,
			`INSERT INTO user_preferences
			   (user_id, cefr_level, learning_goal, daily_goal_words, onboarding_completed_at)
			 VALUES ($1, $2, $3, $4, now())`,
			u.ID, in.CEFRLevel, in.LearningGoal, daily); err != nil {
			return User{}, fmt.Errorf("auth: insert guest preferences: %w", err)
		}
		return u, nil
	})
	if err != nil {
		return Session{}, apperr.Internal(err)
	}
	return s.newSession(ctx, user, nil)
}

// ResetPassword sets a new password after a verified reset code and signs the person in.
func (s *Service) ResetPassword(ctx context.Context, rawEmail, newPassword string) (Session, error) {
	email, err := normalizeEmail(rawEmail)
	if err != nil {
		return Session{}, err
	}

	v, err := s.repo.LatestVerification(ctx, email, PurposePasswordReset)
	if err != nil || v.VerifiedAt == nil || v.ConsumedAt != nil || v.Expired(time.Now()) {
		return Session{}, apperr.New(apperr.CodeInvalidCode, http.StatusForbidden,
			"Verify the code before setting a new password.")
	}

	hash, err := password.Hash(newPassword)
	if err != nil {
		if errors.Is(err, password.ErrTooShort) {
			return Session{}, apperr.New(apperr.CodeInvalidPassword, http.StatusBadRequest,
				fmt.Sprintf("Password must be at least %d characters.", password.MinLength))
		}
		return Session{}, apperr.Internal(err)
	}

	if err := s.repo.SetPasswordHash(ctx, email, hash); err != nil {
		return Session{}, apperr.Internal(err)
	}
	if err := s.repo.ConsumeVerification(ctx, v.ID); err != nil {
		s.log.Warn("verification_not_consumed", slog.String("error", err.Error()))
	}

	user, err := s.repo.UserByEmail(ctx, email)
	if err != nil {
		return Session{}, apperr.Internal(err)
	}

	// Every existing session ends. A password reset usually means the old one was
	// compromised, so leaving other devices signed in would defeat the point.
	if err := s.repo.RevokeAllForUser(ctx, user.ID); err != nil {
		return Session{}, apperr.Internal(err)
	}
	return s.newSession(ctx, user, nil)
}

// Refresh exchanges a refresh token for a new pair.
func (s *Service) Refresh(ctx context.Context, refreshToken string) (Session, error) {
	id, userID, revoked, expiresAt, err := s.repo.RefreshTokenByHash(ctx, token.Hash(refreshToken))
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			return Session{}, sessionExpired()
		}
		return Session{}, apperr.Internal(err)
	}

	if revoked {
		// A revoked token being presented means it was replayed, so it was probably
		// stolen. Every session for this account ends (ARCHITECTURE.md 8.2).
		s.log.Warn("refresh_token_reuse_detected")
		if err := s.repo.RevokeAllForUser(ctx, userID); err != nil {
			return Session{}, apperr.Internal(err)
		}
		return Session{}, sessionExpired()
	}
	if time.Now().After(expiresAt) {
		return Session{}, sessionExpired()
	}

	user, err := s.repo.UserByID(ctx, userID)
	if err != nil {
		return Session{}, sessionExpired()
	}

	// Rotation: the presented token is retired as the new one is issued.
	if err := s.repo.RevokeRefreshToken(ctx, id); err != nil {
		return Session{}, apperr.Internal(err)
	}
	return s.newSession(ctx, user, &id)
}

// Logout revokes one refresh token. A token we do not recognise is not an error: the
// caller wanted to be signed out and now is.
func (s *Service) Logout(ctx context.Context, refreshToken string) error {
	id, _, _, _, err := s.repo.RefreshTokenByHash(ctx, token.Hash(refreshToken))
	if err != nil {
		return nil
	}
	if err := s.repo.RevokeRefreshToken(ctx, id); err != nil {
		return apperr.Internal(err)
	}
	return nil
}

func sessionExpired() *apperr.AppError {
	return apperr.New(apperr.CodeSessionExpired, http.StatusUnauthorized,
		"Your session has expired. Please sign in again.")
}

// newSession issues an access token and a refresh token.
func (s *Service) newSession(ctx context.Context, user User, rotatedFrom *uuid.UUID) (Session, error) {
	access, err := s.issuer.Issue(user.ID.String())
	if err != nil {
		return Session{}, apperr.Internal(err)
	}

	refresh, err := token.NewOpaque()
	if err != nil {
		return Session{}, apperr.Internal(err)
	}
	if _, err := s.repo.StoreRefreshToken(ctx, user.ID, token.Hash(refresh),
		s.policy.RefreshTTL, rotatedFrom); err != nil {
		return Session{}, apperr.Internal(err)
	}

	return Session{
		User:         user,
		AccessToken:  access,
		RefreshToken: refresh,
		ExpiresIn:    int(s.issuer.TTL().Seconds()),
	}, nil
}

// ---------------------------------------------------------------------------
// Preferences
// ---------------------------------------------------------------------------

// SavePreferences stores the onboarding answers. Each screen may save independently;
// values not supplied are left as they were.
func (s *Service) SavePreferences(ctx context.Context, userID uuid.UUID, p Preferences) error {
	if err := validateLevelAndGoal(p.CEFRLevel, p.LearningGoal); err != nil {
		return err
	}
	if p.DailyGoalWords < 0 || p.DailyGoalWords > 200 {
		return apperr.Validation("Daily goal must be between 1 and 200 words.")
	}
	p.UserID = userID
	if err := s.repo.SavePreferences(ctx, p); err != nil {
		return apperr.Internal(err)
	}
	return nil
}

// Preferences reads the stored settings.
func (s *Service) Preferences(ctx context.Context, userID uuid.UUID) (Preferences, error) {
	p, err := s.repo.Preferences(ctx, userID)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			return Preferences{}, apperr.NotFound("Preferences not found.")
		}
		return Preferences{}, apperr.Internal(err)
	}
	return p, nil
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// normalizeEmail lowercases and trims, and rejects anything that is not an address.
func normalizeEmail(raw string) (string, error) {
	trimmed := strings.ToLower(strings.TrimSpace(raw))
	if trimmed == "" {
		return "", apperr.New(apperr.CodeInvalidEmail, http.StatusBadRequest,
			"Enter your email address.")
	}
	if _, err := mail.ParseAddress(trimmed); err != nil {
		return "", apperr.New(apperr.CodeInvalidEmail, http.StatusBadRequest,
			"That does not look like a valid email address.")
	}
	return trimmed, nil
}

func validateLevelAndGoal(level, goal *string) error {
	if level != nil && *level != "" && !ValidLevels[*level] {
		return apperr.Validation("Unknown English level.")
	}
	if goal != nil && *goal != "" && !ValidGoals[*goal] {
		return apperr.Validation("Unknown learning goal.")
	}
	return nil
}

// ---------------------------------------------------------------------------
// Google sign-in
// ---------------------------------------------------------------------------

// SignInWithGoogle verifies a Google identity token and returns a session, creating the
// account on first use.
//
// The token is checked SERVER-SIDE. The app forwards what Google gave it; only this
// backend decides whether that is genuine (ARCHITECTURE.md 8.1).
func (s *Service) SignInWithGoogle(ctx context.Context, idToken string,
	in RegisterInput) (Session, error) {

	if s.google == nil {
		return Session{}, apperr.New(apperr.CodeProviderUnavailable,
			http.StatusServiceUnavailable, "Google sign-in is not available.")
	}
	if err := validateLevelAndGoal(in.CEFRLevel, in.LearningGoal); err != nil {
		return Session{}, err
	}

	identity, err := s.google.Verify(ctx, idToken)
	if err != nil {
		// The reason is logged, never returned: telling a caller why a token was refused
		// helps them craft one that is accepted.
		s.log.Warn("google_token_rejected", slog.String("error", err.Error()))
		return Session{}, apperr.New(apperr.CodeInvalidCredentials,
			http.StatusUnauthorized, "Google sign-in failed. Please try again.")
	}

	// An unverified address from Google is refused. Accepting it would let someone claim
	// an address they do not control and then take over the matching Voca account.
	if identity.Email == "" || !identity.EmailVerified {
		return Session{}, apperr.New(apperr.CodeEmailNotVerified, http.StatusForbidden,
			"Your Google account has no verified email address.")
	}

	email := strings.ToLower(identity.Email)

	// Returning user, matched on the address rather than only on the Google subject: a
	// person who signed up by email and later taps Google is the same person, and
	// creating a second account would split their practice history in two.
	if user, err := s.repo.UserByEmail(ctx, email); err == nil {
		if err := s.repo.LinkGoogleAccount(ctx, user.ID, identity.Subject); err != nil {
			return Session{}, apperr.Internal(err)
		}
		if err := s.repo.TouchLastLogin(ctx, user.ID); err != nil {
			s.log.Warn("last_login_not_recorded", slog.String("error", err.Error()))
		}
		user.EmailVerified = true
		return s.newSession(ctx, user, nil)
	} else if !errors.Is(err, ErrNotFound) {
		return Session{}, apperr.Internal(err)
	}

	// First time: create the account, its profile and its preferences together.
	user, err := s.repo.CreateUserTx(ctx, func(tx pgx.Tx) (User, error) {
		var u User
		if err := tx.QueryRow(ctx,
			`INSERT INTO users (auth_provider, external_auth_id, email, email_verified)
			 VALUES ('google', $1, $2, true)
			 RETURNING `+userColumns, identity.Subject, email).
			Scan(&u.ID, &u.Provider, &u.ExternalAuthID, &u.Email,
				&u.EmailVerified, &u.Status, &u.CreatedAt); err != nil {
			return User{}, fmt.Errorf("auth: insert google user: %w", err)
		}

		if _, err := tx.Exec(ctx,
			`INSERT INTO profiles (user_id, first_name, last_name)
			 VALUES ($1, $2, $3)`,
			u.ID, nullOrValue(in.FirstName), nullOrValue(in.LastName)); err != nil {
			return User{}, fmt.Errorf("auth: insert google profile: %w", err)
		}

		daily := 10
		if in.DailyGoalWords != nil {
			daily = *in.DailyGoalWords
		}
		if _, err := tx.Exec(ctx,
			`INSERT INTO user_preferences
			   (user_id, cefr_level, learning_goal, daily_goal_words, onboarding_completed_at)
			 VALUES ($1, $2, $3, $4, now())`,
			u.ID, in.CEFRLevel, in.LearningGoal, daily); err != nil {
			return User{}, fmt.Errorf("auth: insert google preferences: %w", err)
		}
		return u, nil
	})
	if err != nil {
		return Session{}, apperr.Internal(err)
	}
	return s.newSession(ctx, user, nil)
}

func nullOrValue(v string) *string {
	if strings.TrimSpace(v) == "" {
		return nil
	}
	return &v
}
