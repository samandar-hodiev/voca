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
	"sync"
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
	repo    Repository
	issuer  *jwt.Issuer
	email   EmailProvider
	google  GoogleTokenVerifier
	avatars AvatarStore
	policy  Policy
	log     *slog.Logger

	// notices bounds how often one address is told that somebody tried to sign up with
	// it. Without a bound, anybody can make Voca mail a registered address as fast as the
	// rate limit allows, which harasses the owner and burns the provider's daily quota
	// until sign-up stops working for everyone.
	notices noticeThrottle
}

// noticeThrottle remembers when each address was last sent a notice.
//
// In process, like the rate limiter, and with the same caveat: a second API instance
// would allow a notice per instance. That is the trigger for moving it to Redis alongside
// the rate limit counters.
type noticeThrottle struct {
	mu   sync.Mutex
	last map[string]time.Time
}

// allow reports whether a notice may go to key now, and records it if so.
func (t *noticeThrottle) allow(key string, now time.Time, window time.Duration) bool {
	t.mu.Lock()
	defer t.mu.Unlock()

	if t.last == nil {
		t.last = map[string]time.Time{}
	}
	if sent, ok := t.last[key]; ok && now.Sub(sent) < window {
		return false
	}

	// Forget addresses whose window has passed, so the map does not grow with every
	// address that was ever typed into the sign-up form.
	for k, sent := range t.last {
		if now.Sub(sent) >= window {
			delete(t.last, k)
		}
	}

	t.last[key] = now
	return true
}

// NewService builds the service. A nil google verifier is allowed: Google sign-in then
// reports itself unavailable rather than the service refusing to start.
func NewService(repo Repository, issuer *jwt.Issuer, emailProvider EmailProvider,
	google GoogleTokenVerifier, avatars AvatarStore, policy Policy,
	log *slog.Logger) *Service {
	return &Service{
		repo: repo, issuer: issuer, email: emailProvider,
		google: google, avatars: avatars, policy: policy, log: log,
	}
}

// ---------------------------------------------------------------------------
// Email verification
// ---------------------------------------------------------------------------

// StartEmailVerification issues a one-time code for signing up.
//
// An address that already has an account is told so, rather than being answered as if a
// code had been sent. Staying silent is the stricter choice against address enumeration,
// but in practice it strands the person: the app says a code is on its way, nothing
// arrives, and there is no way to tell a forgotten account from a broken product.
//
// What keeps enumeration expensive instead is the rate limit on this group. At the default
// of twenty attempts a minute, walking a list of a million addresses takes over a month
// from one address (ADR-018).
func (s *Service) StartEmailVerification(ctx context.Context, rawEmail string) error {
	email, err := normalizeEmail(rawEmail)
	if err != nil {
		return err
	}

	if _, err := s.repo.UserByEmail(ctx, email); err == nil {
		s.log.Info("signup_attempt_on_existing_account")

		// The address is also told by email, because somebody who did not try to sign up
		// should learn that an attempt was made. That message carries no code and no
		// sign-in link, so it cannot let in whoever typed the address. A failure to send
		// it must not change the answer the app gets.
		//
		// At most once per resend window per address. The answer to the app does not
		// change when a notice is skipped, so the throttle cannot be observed from outside.
		if s.notices.allow(email, time.Now(), s.policy.ResendWindow) {
			if err := s.email.Send(ctx, EmailMessage{
				To:       email,
				Template: TemplateAccountExists,
			}); err != nil {
				s.log.Error("account_exists_email_failed", slog.String("error", err.Error()))
			}
		} else {
			s.log.Info("account_exists_notice_throttled")
		}

		return apperr.New(apperr.CodeEmailAlreadyExists, http.StatusConflict,
			"Bu pochta bilan akkaunt allaqachon ochilgan. "+
				"Kirish tugmasidan foydalaning yoki parolni tiklang.")
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
		// The code has already been stored, so the person can still finish if a later
		// attempt gets through. The message deliberately does not repeat the provider's
		// reason: that text names the account that owns the mail provider, which is not
		// something to hand to whoever typed the address.
		s.log.Error("verification_email_failed",
			slog.String("to", email),
			slog.String("error", err.Error()))
		return apperr.New(apperr.CodeProviderUnavailable, http.StatusServiceUnavailable,
			"Hozircha bu manzilga xat yubora olmadik. "+
				"Biroz kutib qayta urinib ko‘ring yoki boshqa pochta kiriting.")
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
		return Session{}, apperr.Validation("Ism va familiya kiritilishi shart.")
	}
	// Checked on the server, not only in the form. A client is free to send whatever it
	// likes, so a rule that only exists in the app is not a rule.
	phone, err := normalizePhone(in.Phone)
	if err != nil {
		return Session{}, err
	}
	in.Phone = &phone

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
		if errors.Is(err, ErrNotFound) {
			// A guest or a Google account has no password. Hash anyway so it takes as long
			// as a wrong password does; answering at once would reveal that the address
			// belongs to an account that signs in some other way.
			_, _ = password.Hash("timing-equalizer-value")
			return Session{}, invalidCredentials()
		}
		return Session{}, apperr.Internal(err)
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

// ---------------------------------------------------------------------------
// Confirmed sign-out
// ---------------------------------------------------------------------------

// StartSignOut sends a one-time code to the signed-in person's own address, the first
// half of a sign-out they confirm from their mailbox.
//
// The address typed in the app has to be the account's own. The comparison happens here,
// not only in the app, and a mismatch sends nothing: the code can only ever reach the
// mailbox that already owns the account, so typing another address gains nothing.
func (s *Service) StartSignOut(ctx context.Context, userID uuid.UUID, rawEmail string) error {
	account, err := s.signOutAddress(ctx, userID)
	if err != nil {
		return err
	}
	typed, err := normalizeEmail(rawEmail)
	if err != nil {
		return err
	}
	if typed != account {
		return apperr.New(apperr.CodeEmailMismatch, http.StatusBadRequest,
			"Bu pochta hisobingizga tegishli emas. Hisob ochilgan pochtani kiriting.")
	}
	return s.issueCode(ctx, account, PurposeSignOut, TemplateSignOutCode)
}

// ConfirmSignOut checks the emailed code and only then revokes the session.
//
// The code is consumed on success, so it cannot end a later session as well. Only a
// refresh token that belongs to the caller is revoked: a token from somebody else's
// session is left alone rather than letting one account sign another out.
func (s *Service) ConfirmSignOut(ctx context.Context, userID uuid.UUID,
	code, refreshToken string) error {

	account, err := s.signOutAddress(ctx, userID)
	if err != nil {
		return err
	}
	if err := s.VerifyCode(ctx, account, PurposeSignOut, code); err != nil {
		return err
	}
	v, err := s.repo.LatestVerification(ctx, account, PurposeSignOut)
	if err != nil {
		return apperr.Internal(err)
	}
	if err := s.repo.ConsumeVerification(ctx, v.ID); err != nil {
		return apperr.Internal(err)
	}

	id, owner, _, _, err := s.repo.RefreshTokenByHash(ctx, token.Hash(refreshToken))
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			// Already gone. The person asked to be signed out and is.
			return nil
		}
		return apperr.Internal(err)
	}
	if owner != userID {
		s.log.Warn("sign_out_token_owner_mismatch")
		return nil
	}
	if err := s.repo.RevokeRefreshToken(ctx, id); err != nil {
		return apperr.Internal(err)
	}
	return nil
}

// signOutAddress is where a sign-out code goes: the account's own address, normalised.
// StartAccountDeletion sends a deletion code to the account's own address.
//
// Deliberately identical in shape to StartSignOut: the address comes from the session, the
// one typed by the caller only has to match it, and a mismatch sends nothing at all. A
// guest has no mailbox and cannot reach this, which is correct — there is no identity to
// prove and nothing of theirs is kept on the server.
func (s *Service) StartAccountDeletion(ctx context.Context, userID uuid.UUID, rawEmail string) error {
	account, err := s.signOutAddress(ctx, userID)
	if err != nil {
		return err
	}
	typed, err := normalizeEmail(rawEmail)
	if err != nil {
		return err
	}
	if typed != account {
		return apperr.New(apperr.CodeEmailMismatch, http.StatusBadRequest,
			"Bu pochta hisobingizga tegishli emas. Hisob ochilgan pochtani kiriting.")
	}
	return s.issueCode(ctx, account, PurposeDeleteAccount, TemplateDeleteAccountCode)
}

// ConfirmAccountDeletion deletes the account once the emailed code is right.
//
// Order matters. The code is checked and consumed first, so a wrong or replayed code
// destroys nothing. Only then is the account marked deleted and every session revoked, in
// that order: a revoked token on a live account is a nuisance, a live token on a deleted
// account is a hole.
func (s *Service) ConfirmAccountDeletion(ctx context.Context, userID uuid.UUID, code string) error {
	account, err := s.signOutAddress(ctx, userID)
	if err != nil {
		return err
	}
	if err := s.VerifyCode(ctx, account, PurposeDeleteAccount, code); err != nil {
		return err
	}
	v, err := s.repo.LatestVerification(ctx, account, PurposeDeleteAccount)
	if err != nil {
		return apperr.Internal(err)
	}
	if err := s.repo.ConsumeVerification(ctx, v.ID); err != nil {
		return apperr.Internal(err)
	}

	if err := s.repo.SoftDeleteUser(ctx, userID); err != nil {
		return apperr.Internal(err)
	}
	if err := s.repo.RevokeAllForUser(ctx, userID); err != nil {
		return apperr.Internal(err)
	}
	// The account is gone and its sessions with it. Nothing about the person is logged.
	s.log.Info("account_deleted")
	return nil
}

func (s *Service) signOutAddress(ctx context.Context, userID uuid.UUID) (string, error) {
	user, err := s.repo.UserByID(ctx, userID)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			return "", apperr.Unauthenticated("Authentication required.")
		}
		return "", apperr.Internal(err)
	}
	if user.Email == nil || *user.Email == "" {
		// A guest has no mailbox to confirm from. The app signs a guest out after a plain
		// confirmation and never calls this.
		return "", apperr.Validation("Bu hisobda pochta yo‘q.")
	}
	return normalizeEmail(*user.Email)
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

// SaveAvatar stores a profile picture and points the account at it.
//
// The old picture is removed afterwards rather than before: if the write fails the
// account is left with the image it already had, instead of with none.
func (s *Service) SaveAvatar(ctx context.Context, userID uuid.UUID,
	contentType string, data []byte) (string, error) {

	if s.avatars == nil {
		return "", apperr.New(apperr.CodeProviderUnavailable, http.StatusServiceUnavailable,
			"Rasm yuklash hozircha ishlamayapti.")
	}

	previous, err := s.repo.AvatarURL(ctx, userID)
	if err != nil && !errors.Is(err, ErrNotFound) {
		return "", apperr.Internal(err)
	}

	url, err := s.avatars.Put(ctx, userID.String(), contentType, data)
	if err != nil {
		// The reason names a size or a file type, both of which the person can act on,
		// so it is worth returning rather than hiding behind a generic message.
		s.log.Info("avatar_rejected", slog.String("error", err.Error()))
		return "", apperr.Validation("Rasmni yuklab bo‘lmadi. " +
			"JPEG, PNG yoki WebP formatida va 2 MB dan kichik bo‘lsin.")
	}

	if err := s.repo.SetAvatarURL(ctx, userID, url); err != nil {
		// The stored file is now orphaned, so clean it up rather than leaving it behind.
		_ = s.avatars.Remove(ctx, url)
		return "", apperr.Internal(err)
	}

	if previous != "" && previous != url {
		if err := s.avatars.Remove(ctx, previous); err != nil {
			// Not worth failing the request: the new picture is already in place.
			s.log.Warn("old_avatar_not_removed", slog.String("error", err.Error()))
		}
	}

	return url, nil
}

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

// normalizePhone checks a phone number and returns it in a single stored form.
//
// Stored as digits with a leading plus, so the same number typed as "+998 90 123 45 67",
// "998901234567" or "(90) 123-45-67" is one value in the database rather than three.
// Uzbek numbers are accepted without the country code and get +998 added, because that is
// how people here write their own number.
func normalizePhone(raw *string) (string, error) {
	const invalid = "Telefon raqamni to‘g‘ri kiriting, masalan +998 90 123 45 67."

	if raw == nil {
		return "", apperr.Validation("Telefon raqam kiritilishi shart.")
	}

	var digits strings.Builder
	for _, r := range *raw {
		if r >= '0' && r <= '9' {
			digits.WriteRune(r)
		}
	}
	d := digits.String()

	switch {
	case d == "":
		return "", apperr.Validation("Telefon raqam kiritilishi shart.")

	// A local Uzbek number: nine digits, no country code.
	case len(d) == 9:
		d = "998" + d

	// Written with a leading zero before the operator code, which is how it is dialled
	// inside the country but is not part of the international number.
	case len(d) == 10 && strings.HasPrefix(d, "0"):
		d = "998" + d[1:]

	// Long enough to carry a country code already. The upper bound is the E.164 limit.
	case len(d) >= 11 && len(d) <= 15:

	default:
		return "", apperr.Validation(invalid)
	}

	return "+" + d, nil
}

// ProfileInfo is the part of a profile a signed-in person sees about themselves.
type ProfileInfo struct {
	FirstName *string
	LastName  *string
	Phone     *string
	AvatarURL *string
}

// Me is everything the app needs to render the signed-in person: who they are, what they
// look like and how they want to practise. One call instead of three, because every
// screen that shows one of these shows the others.
type Me struct {
	User        User
	Profile     ProfileInfo
	Preferences Preferences
}

// UpdateProfile changes the name and number on the signed-in person's profile.
//
// The account's address is not editable here. Changing it would change how the person
// signs in and where every confirmation code goes, so it belongs to a flow of its own that
// proves the new address first.
//
// The number is normalised the same way sign-up normalises it, so a profile edited later
// is stored exactly as one filled in at the start.
func (s *Service) UpdateProfile(ctx context.Context, userID uuid.UUID,
	rawFirst, rawLast string, rawPhone *string) error {

	first := strings.TrimSpace(rawFirst)
	last := strings.TrimSpace(rawLast)
	if first == "" {
		return apperr.Validation("Ismni kiriting.")
	}
	if last == "" {
		return apperr.Validation("Familiyani kiriting.")
	}

	phone, err := normalizePhone(rawPhone)
	if err != nil {
		return err
	}

	if err := s.repo.UpdateProfile(ctx, userID, first, last, phone); err != nil {
		if errors.Is(err, ErrNotFound) {
			return apperr.New(apperr.CodeNotFound, http.StatusNotFound,
				"Profil topilmadi.")
		}
		return apperr.Internal(err)
	}
	return nil
}

// Me returns the signed-in person's account, profile and preferences.
func (s *Service) Me(ctx context.Context, userID uuid.UUID) (Me, error) {
	user, err := s.repo.UserByID(ctx, userID)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			return Me{}, apperr.Unauthenticated("Authentication required.")
		}
		return Me{}, apperr.Internal(err)
	}

	profile, err := s.repo.Profile(ctx, userID)
	if err != nil && !errors.Is(err, ErrNotFound) {
		return Me{}, apperr.Internal(err)
	}

	prefs, err := s.Preferences(ctx, userID)
	if err != nil {
		return Me{}, err
	}

	return Me{User: user, Profile: profile, Preferences: prefs}, nil
}

// splitDisplayName turns "Samandar Xodiev" into its two halves.
//
// A display name is one free-text field, so this is a guess rather than a parse: the first
// word is the given name and whatever follows is the family name. Somebody with one word,
// or three, still ends up with something usable, which is all the profile needs until they
// edit it.
func splitDisplayName(full string) (first, last string) {
	fields := strings.Fields(full)
	switch len(fields) {
	case 0:
		return "", ""
	case 1:
		return fields[0], ""
	default:
		return fields[0], strings.Join(fields[1:], " ")
	}
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

		// The name and picture come from the verified token, never from the request
		// body. A client can send any name it likes, and believing it would let somebody
		// sign in as one identity while presenting somebody else's details.
		first, last := splitDisplayName(identity.DisplayName)
		if _, err := tx.Exec(ctx,
			`INSERT INTO profiles (user_id, first_name, last_name, avatar_url)
			 VALUES ($1, $2, $3, $4)`,
			u.ID, nullOrValue(first), nullOrValue(last),
			nullOrValue(identity.PhotoURL)); err != nil {
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
