// Data access for identity, preferences, verification challenges and sessions.
//
// Translates rows to and from domain models and contains no business rules
// (ARCHITECTURE.md 5.3).
package auth

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// ErrNotFound is returned when a row does not exist. The service decides what that means
// to a client; the repository does not.
var ErrNotFound = errors.New("auth: not found")

// Repository is the persistence contract the service depends on. Defined here, next to
// its consumer, so a test can substitute it.
type Repository interface {
	CreateUserTx(ctx context.Context, fn func(tx pgx.Tx) (User, error)) (User, error)

	UserByEmail(ctx context.Context, email string) (User, error)
	UserByID(ctx context.Context, id uuid.UUID) (User, error)
	PasswordHash(ctx context.Context, userID uuid.UUID) (string, error)
	LinkGoogleAccount(ctx context.Context, userID uuid.UUID, subject string) error
	SetPasswordHash(ctx context.Context, email, hash string) error
	TouchLastLogin(ctx context.Context, userID uuid.UUID) error

	Preferences(ctx context.Context, userID uuid.UUID) (Preferences, error)
	SavePreferences(ctx context.Context, p Preferences) error

	CreateVerification(ctx context.Context, email string, purpose VerificationPurpose,
		codeHash string, ttl time.Duration, maxAttempts int) (Verification, error)
	LatestVerification(ctx context.Context, email string, purpose VerificationPurpose) (Verification, error)
	VerificationCodeHash(ctx context.Context, id uuid.UUID) (string, error)
	RecordVerificationAttempt(ctx context.Context, id uuid.UUID) error
	MarkVerified(ctx context.Context, id uuid.UUID) error
	ConsumeVerification(ctx context.Context, id uuid.UUID) error
	CountRecentVerifications(ctx context.Context, email string, purpose VerificationPurpose,
		within time.Duration) (int, error)

	StoreRefreshToken(ctx context.Context, userID uuid.UUID, hash string,
		ttl time.Duration, rotatedFrom *uuid.UUID) (uuid.UUID, error)
	RefreshTokenByHash(ctx context.Context, hash string) (id uuid.UUID, userID uuid.UUID,
		revoked bool, expiresAt time.Time, err error)
	RevokeRefreshToken(ctx context.Context, id uuid.UUID) error
	RevokeAllForUser(ctx context.Context, userID uuid.UUID) error
}

type repository struct {
	pool *pgxpool.Pool
}

// NewRepository builds the PostgreSQL repository.
func NewRepository(pool *pgxpool.Pool) Repository { return &repository{pool: pool} }

// CreateUserTx runs fn inside a transaction.
//
// Account creation writes a user, a profile and a preferences row. Either all three
// exist or none do: a half-registered account cannot log in and cannot be created again,
// because the address is already taken (task requirement, transaction safety).
func (r *repository) CreateUserTx(ctx context.Context, fn func(tx pgx.Tx) (User, error)) (User, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return User{}, fmt.Errorf("auth: begin: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	user, err := fn(tx)
	if err != nil {
		return User{}, err
	}
	if err := tx.Commit(ctx); err != nil {
		return User{}, fmt.Errorf("auth: commit: %w", err)
	}
	return user, nil
}

const userColumns = `id, auth_provider, external_auth_id, email, email_verified, status, created_at`

func scanUser(row pgx.Row) (User, error) {
	var u User
	err := row.Scan(&u.ID, &u.Provider, &u.ExternalAuthID, &u.Email,
		&u.EmailVerified, &u.Status, &u.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return User{}, ErrNotFound
	}
	if err != nil {
		return User{}, fmt.Errorf("auth: scan user: %w", err)
	}
	return u, nil
}

func (r *repository) UserByEmail(ctx context.Context, email string) (User, error) {
	return scanUser(r.pool.QueryRow(ctx,
		`SELECT `+userColumns+` FROM users
		 WHERE email = $1 AND deleted_at IS NULL`, email))
}

func (r *repository) UserByID(ctx context.Context, id uuid.UUID) (User, error) {
	return scanUser(r.pool.QueryRow(ctx,
		`SELECT `+userColumns+` FROM users
		 WHERE id = $1 AND deleted_at IS NULL`, id))
}

func (r *repository) PasswordHash(ctx context.Context, userID uuid.UUID) (string, error) {
	var hash *string
	err := r.pool.QueryRow(ctx,
		`SELECT password_hash FROM users WHERE id = $1 AND deleted_at IS NULL`,
		userID).Scan(&hash)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", ErrNotFound
	}
	if err != nil {
		return "", fmt.Errorf("auth: read password hash: %w", err)
	}
	if hash == nil {
		// A guest or a social account. Not an error, but not a password login either.
		return "", ErrNotFound
	}
	return *hash, nil
}

func (r *repository) SetPasswordHash(ctx context.Context, email, hash string) error {
	tag, err := r.pool.Exec(ctx,
		`UPDATE users SET password_hash = $2, updated_at = now()
		 WHERE email = $1 AND deleted_at IS NULL`, email, hash)
	if err != nil {
		return fmt.Errorf("auth: set password: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *repository) TouchLastLogin(ctx context.Context, userID uuid.UUID) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE users SET last_login_at = now() WHERE id = $1`, userID)
	if err != nil {
		return fmt.Errorf("auth: touch last login: %w", err)
	}
	return nil
}

func (r *repository) Preferences(ctx context.Context, userID uuid.UUID) (Preferences, error) {
	var p Preferences
	err := r.pool.QueryRow(ctx,
		`SELECT user_id, cefr_level, learning_goal, daily_goal_words, ui_language,
		        learning_language, accent, timezone, onboarding_completed_at
		 FROM user_preferences WHERE user_id = $1`, userID).
		Scan(&p.UserID, &p.CEFRLevel, &p.LearningGoal, &p.DailyGoalWords,
			&p.UILanguage, &p.LearningLanguage, &p.Accent, &p.Timezone,
			&p.OnboardingCompletedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return Preferences{}, ErrNotFound
	}
	if err != nil {
		return Preferences{}, fmt.Errorf("auth: read preferences: %w", err)
	}
	return p, nil
}

func (r *repository) SavePreferences(ctx context.Context, p Preferences) error {
	// COALESCE keeps a previously stored answer when this request does not carry one, so
	// the three onboarding screens can each save independently without clearing the
	// others.
	_, err := r.pool.Exec(ctx,
		`UPDATE user_preferences SET
		    cefr_level              = COALESCE($2, cefr_level),
		    learning_goal           = COALESCE($3, learning_goal),
		    daily_goal_words        = COALESCE($4, daily_goal_words),
		    timezone                = COALESCE($5, timezone),
		    onboarding_completed_at = COALESCE($6, onboarding_completed_at),
		    updated_at              = now()
		 WHERE user_id = $1`,
		p.UserID, p.CEFRLevel, p.LearningGoal,
		nullableInt(p.DailyGoalWords), nullableString(p.Timezone),
		p.OnboardingCompletedAt)
	if err != nil {
		return fmt.Errorf("auth: save preferences: %w", err)
	}
	return nil
}

func nullableInt(v int) *int {
	if v == 0 {
		return nil
	}
	return &v
}

func nullableString(v string) *string {
	if v == "" {
		return nil
	}
	return &v
}

// ---------------------------------------------------------------------------
// Verification challenges
// ---------------------------------------------------------------------------

const verificationColumns = `id, email, purpose, attempts, max_attempts,
	expires_at, consumed_at, verified_at, created_at`

func scanVerification(row pgx.Row) (Verification, error) {
	var v Verification
	err := row.Scan(&v.ID, &v.Email, &v.Purpose, &v.Attempts, &v.MaxAttempts,
		&v.ExpiresAt, &v.ConsumedAt, &v.VerifiedAt, &v.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return Verification{}, ErrNotFound
	}
	if err != nil {
		return Verification{}, fmt.Errorf("auth: scan verification: %w", err)
	}
	return v, nil
}

func (r *repository) CreateVerification(ctx context.Context, email string,
	purpose VerificationPurpose, codeHash string, ttl time.Duration,
	maxAttempts int) (Verification, error) {

	// Any earlier live challenge for this address and purpose is consumed first, so only
	// the newest code can ever be used. Without this, an old code stays valid for its
	// whole lifetime after a resend.
	if _, err := r.pool.Exec(ctx,
		`UPDATE email_verifications SET consumed_at = now()
		 WHERE email = $1 AND purpose = $2 AND consumed_at IS NULL`,
		email, purpose); err != nil {
		return Verification{}, fmt.Errorf("auth: supersede verifications: %w", err)
	}

	return scanVerification(r.pool.QueryRow(ctx,
		`INSERT INTO email_verifications (email, purpose, code_hash, expires_at, max_attempts)
		 VALUES ($1, $2, $3, now() + $4::interval, $5)
		 RETURNING `+verificationColumns,
		email, purpose, codeHash, ttl.String(), maxAttempts))
}

func (r *repository) LatestVerification(ctx context.Context, email string,
	purpose VerificationPurpose) (Verification, error) {

	return scanVerification(r.pool.QueryRow(ctx,
		`SELECT `+verificationColumns+` FROM email_verifications
		 WHERE email = $1 AND purpose = $2
		 ORDER BY created_at DESC LIMIT 1`, email, purpose))
}

func (r *repository) VerificationCodeHash(ctx context.Context, id uuid.UUID) (string, error) {
	var hash string
	err := r.pool.QueryRow(ctx,
		`SELECT code_hash FROM email_verifications WHERE id = $1`, id).Scan(&hash)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", ErrNotFound
	}
	if err != nil {
		return "", fmt.Errorf("auth: read code hash: %w", err)
	}
	return hash, nil
}

func (r *repository) RecordVerificationAttempt(ctx context.Context, id uuid.UUID) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE email_verifications SET attempts = attempts + 1 WHERE id = $1`, id)
	if err != nil {
		return fmt.Errorf("auth: record attempt: %w", err)
	}
	return nil
}

func (r *repository) MarkVerified(ctx context.Context, id uuid.UUID) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE email_verifications SET verified_at = now() WHERE id = $1`, id)
	if err != nil {
		return fmt.Errorf("auth: mark verified: %w", err)
	}
	return nil
}

func (r *repository) ConsumeVerification(ctx context.Context, id uuid.UUID) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE email_verifications SET consumed_at = now() WHERE id = $1`, id)
	if err != nil {
		return fmt.Errorf("auth: consume verification: %w", err)
	}
	return nil
}

// CountRecentVerifications backs the resend rate limit.
func (r *repository) CountRecentVerifications(ctx context.Context, email string,
	purpose VerificationPurpose, within time.Duration) (int, error) {

	var n int
	err := r.pool.QueryRow(ctx,
		`SELECT count(*) FROM email_verifications
		 WHERE email = $1 AND purpose = $2 AND created_at > now() - $3::interval`,
		email, purpose, within.String()).Scan(&n)
	if err != nil {
		return 0, fmt.Errorf("auth: count verifications: %w", err)
	}
	return n, nil
}

// ---------------------------------------------------------------------------
// Refresh tokens
// ---------------------------------------------------------------------------

func (r *repository) StoreRefreshToken(ctx context.Context, userID uuid.UUID, hash string,
	ttl time.Duration, rotatedFrom *uuid.UUID) (uuid.UUID, error) {

	var id uuid.UUID
	err := r.pool.QueryRow(ctx,
		`INSERT INTO refresh_tokens (user_id, token_hash, expires_at, rotated_from)
		 VALUES ($1, $2, now() + $3::interval, $4)
		 RETURNING id`,
		userID, hash, ttl.String(), rotatedFrom).Scan(&id)
	if err != nil {
		return uuid.Nil, fmt.Errorf("auth: store refresh token: %w", err)
	}
	return id, nil
}

func (r *repository) RefreshTokenByHash(ctx context.Context, hash string) (
	uuid.UUID, uuid.UUID, bool, time.Time, error) {

	var id, userID uuid.UUID
	var revokedAt *time.Time
	var expiresAt time.Time

	err := r.pool.QueryRow(ctx,
		`SELECT id, user_id, revoked_at, expires_at FROM refresh_tokens
		 WHERE token_hash = $1`, hash).Scan(&id, &userID, &revokedAt, &expiresAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return uuid.Nil, uuid.Nil, false, time.Time{}, ErrNotFound
	}
	if err != nil {
		return uuid.Nil, uuid.Nil, false, time.Time{}, fmt.Errorf("auth: read refresh token: %w", err)
	}
	return id, userID, revokedAt != nil, expiresAt, nil
}

func (r *repository) RevokeRefreshToken(ctx context.Context, id uuid.UUID) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE refresh_tokens SET revoked_at = now() WHERE id = $1 AND revoked_at IS NULL`, id)
	if err != nil {
		return fmt.Errorf("auth: revoke refresh token: %w", err)
	}
	return nil
}

// RevokeAllForUser ends every session.
//
// Used on password reset and on refresh-token reuse: if a token was replayed we must
// assume it was stolen, so the entire family goes (ARCHITECTURE.md 8.2).
func (r *repository) RevokeAllForUser(ctx context.Context, userID uuid.UUID) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE refresh_tokens SET revoked_at = now()
		 WHERE user_id = $1 AND revoked_at IS NULL`, userID)
	if err != nil {
		return fmt.Errorf("auth: revoke user tokens: %w", err)
	}
	return nil
}

// LinkGoogleAccount records the Google subject on an existing account.
//
// Called when someone who signed up by email later uses Google: the same person, so the
// same row, rather than a second account holding half their history.
func (r *repository) LinkGoogleAccount(ctx context.Context, userID uuid.UUID, subject string) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE users
		 SET external_auth_id = COALESCE(external_auth_id, $2),
		     email_verified   = true,
		     updated_at       = now()
		 WHERE id = $1`, userID, subject)
	if err != nil {
		return fmt.Errorf("auth: link google account: %w", err)
	}
	return nil
}
