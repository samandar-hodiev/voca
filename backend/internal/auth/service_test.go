package auth

import (
	"context"
	"errors"
	"io"
	"log/slog"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/samandar-hodiev/voca/backend/internal/shared/apperr"
	"github.com/samandar-hodiev/voca/backend/pkg/jwt"
	"github.com/samandar-hodiev/voca/backend/pkg/password"
	"github.com/samandar-hodiev/voca/backend/pkg/token"
)

// ---------------------------------------------------------------------------
// Fake repository
//
// Hand-written rather than generated: the interface is small, and a fake that stores
// plain maps makes each test's setup obvious at a glance.
// ---------------------------------------------------------------------------

type fakeRepo struct {
	users         map[string]User
	hashes        map[uuid.UUID]string
	prefs         map[uuid.UUID]Preferences
	verifications []Verification
	codeHashes    map[uuid.UUID]string
	refresh       map[string]refreshRow
	avatars       map[uuid.UUID]string
	profiles      map[uuid.UUID]ProfileInfo
	createErr     error

	// Set by a test to say which address the next created account should carry, since
	// the fake cannot run the real INSERT.
	nextEmail string
}

type refreshRow struct {
	id        uuid.UUID
	userID    uuid.UUID
	revoked   bool
	expiresAt time.Time
}

func newFakeRepo() *fakeRepo {
	return &fakeRepo{
		users:      map[string]User{},
		hashes:     map[uuid.UUID]string{},
		prefs:      map[uuid.UUID]Preferences{},
		codeHashes: map[uuid.UUID]string{},
		refresh:    map[string]refreshRow{},
	}
}

// addUser seeds a registered account with a password.
func (f *fakeRepo) addUser(email, plainPassword string) User {
	u := User{ID: uuid.New(), Provider: ProviderEmail, Email: &email,
		EmailVerified: true, Status: "active", CreatedAt: time.Now()}
	f.users[email] = u
	if plainPassword != "" {
		h, _ := password.Hash(plainPassword)
		f.hashes[u.ID] = h
	}
	f.prefs[u.ID] = Preferences{UserID: u.ID, DailyGoalWords: 10, UILanguage: "uz"}
	return u
}

// addVerification seeds a challenge and returns the plaintext code.
func (f *fakeRepo) addVerification(email string, purpose VerificationPurpose,
	code string, expires time.Time, attempts int, verified bool) Verification {
	v := Verification{
		ID: uuid.New(), Email: email, Purpose: purpose,
		Attempts: attempts, MaxAttempts: 5, ExpiresAt: expires, CreatedAt: time.Now(),
	}
	if verified {
		now := time.Now()
		v.VerifiedAt = &now
	}
	f.verifications = append(f.verifications, v)
	f.codeHashes[v.ID] = token.Hash(code)
	return v
}

func (f *fakeRepo) CreateUserTx(ctx context.Context, fn func(tx pgx.Tx) (User, error)) (User, error) {
	if f.createErr != nil {
		return User{}, f.createErr
	}
	// The real implementation runs fn inside a transaction. The fake cannot supply a
	// pgx.Tx, so it records the account directly; what the tests here care about is the
	// service's decisions, not the SQL.
	u := User{ID: uuid.New(), Provider: ProviderEmail, Status: "active", CreatedAt: time.Now()}
	if f.nextEmail != "" {
		e := f.nextEmail
		u.Email = &e
		u.EmailVerified = true
		f.users[e] = u
		f.nextEmail = ""
	}
	return u, nil
}

func (f *fakeRepo) Profile(_ context.Context, userID uuid.UUID) (ProfileInfo, error) {
	p, ok := f.profiles[userID]
	if !ok {
		return ProfileInfo{}, ErrNotFound
	}
	return p, nil
}

func (f *fakeRepo) AvatarURL(_ context.Context, userID uuid.UUID) (string, error) {
	url, ok := f.avatars[userID]
	if !ok {
		return "", nil
	}
	return url, nil
}

func (f *fakeRepo) SetAvatarURL(_ context.Context, userID uuid.UUID, url string) error {
	if f.avatars == nil {
		f.avatars = map[uuid.UUID]string{}
	}
	f.avatars[userID] = url
	return nil
}

func (f *fakeRepo) UserByEmail(_ context.Context, email string) (User, error) {
	u, ok := f.users[email]
	if !ok {
		return User{}, ErrNotFound
	}
	return u, nil
}

func (f *fakeRepo) UserByID(_ context.Context, id uuid.UUID) (User, error) {
	for _, u := range f.users {
		if u.ID == id {
			return u, nil
		}
	}
	return User{}, ErrNotFound
}

func (f *fakeRepo) PasswordHash(_ context.Context, id uuid.UUID) (string, error) {
	h, ok := f.hashes[id]
	if !ok {
		return "", ErrNotFound
	}
	return h, nil
}

func (f *fakeRepo) SetPasswordHash(_ context.Context, email, hash string) error {
	u, ok := f.users[email]
	if !ok {
		return ErrNotFound
	}
	f.hashes[u.ID] = hash
	return nil
}

func (f *fakeRepo) TouchLastLogin(context.Context, uuid.UUID) error { return nil }

func (f *fakeRepo) LinkGoogleAccount(_ context.Context, id uuid.UUID, subject string) error {
	for email, u := range f.users {
		if u.ID == id {
			u.ExternalAuthID = &subject
			u.EmailVerified = true
			f.users[email] = u
		}
	}
	return nil
}

func (f *fakeRepo) Preferences(_ context.Context, id uuid.UUID) (Preferences, error) {
	p, ok := f.prefs[id]
	if !ok {
		return Preferences{}, ErrNotFound
	}
	return p, nil
}

func (f *fakeRepo) SavePreferences(_ context.Context, p Preferences) error {
	f.prefs[p.UserID] = p
	return nil
}

func (f *fakeRepo) CreateVerification(_ context.Context, email string,
	purpose VerificationPurpose, codeHash string, ttl time.Duration,
	maxAttempts int) (Verification, error) {
	v := Verification{ID: uuid.New(), Email: email, Purpose: purpose,
		MaxAttempts: maxAttempts, ExpiresAt: time.Now().Add(ttl), CreatedAt: time.Now()}
	f.verifications = append(f.verifications, v)
	f.codeHashes[v.ID] = codeHash
	return v, nil
}

func (f *fakeRepo) LatestVerification(_ context.Context, email string,
	purpose VerificationPurpose) (Verification, error) {
	for i := len(f.verifications) - 1; i >= 0; i-- {
		v := f.verifications[i]
		if v.Email == email && v.Purpose == purpose {
			return v, nil
		}
	}
	return Verification{}, ErrNotFound
}

func (f *fakeRepo) VerificationCodeHash(_ context.Context, id uuid.UUID) (string, error) {
	h, ok := f.codeHashes[id]
	if !ok {
		return "", ErrNotFound
	}
	return h, nil
}

func (f *fakeRepo) RecordVerificationAttempt(_ context.Context, id uuid.UUID) error {
	for i := range f.verifications {
		if f.verifications[i].ID == id {
			f.verifications[i].Attempts++
		}
	}
	return nil
}

func (f *fakeRepo) MarkVerified(_ context.Context, id uuid.UUID) error {
	now := time.Now()
	for i := range f.verifications {
		if f.verifications[i].ID == id {
			f.verifications[i].VerifiedAt = &now
		}
	}
	return nil
}

func (f *fakeRepo) ConsumeVerification(_ context.Context, id uuid.UUID) error {
	now := time.Now()
	for i := range f.verifications {
		if f.verifications[i].ID == id {
			f.verifications[i].ConsumedAt = &now
		}
	}
	return nil
}

func (f *fakeRepo) CountRecentVerifications(_ context.Context, email string,
	purpose VerificationPurpose, _ time.Duration) (int, error) {
	n := 0
	for _, v := range f.verifications {
		if v.Email == email && v.Purpose == purpose {
			n++
		}
	}
	return n, nil
}

func (f *fakeRepo) StoreRefreshToken(_ context.Context, userID uuid.UUID, hash string,
	ttl time.Duration, _ *uuid.UUID) (uuid.UUID, error) {
	id := uuid.New()
	f.refresh[hash] = refreshRow{id: id, userID: userID, expiresAt: time.Now().Add(ttl)}
	return id, nil
}

func (f *fakeRepo) RefreshTokenByHash(_ context.Context, hash string) (
	uuid.UUID, uuid.UUID, bool, time.Time, error) {
	r, ok := f.refresh[hash]
	if !ok {
		return uuid.Nil, uuid.Nil, false, time.Time{}, ErrNotFound
	}
	return r.id, r.userID, r.revoked, r.expiresAt, nil
}

func (f *fakeRepo) RevokeRefreshToken(_ context.Context, id uuid.UUID) error {
	for h, r := range f.refresh {
		if r.id == id {
			r.revoked = true
			f.refresh[h] = r
		}
	}
	return nil
}

func (f *fakeRepo) RevokeAllForUser(_ context.Context, userID uuid.UUID) error {
	for h, r := range f.refresh {
		if r.userID == userID {
			r.revoked = true
			f.refresh[h] = r
		}
	}
	return nil
}

// ---------------------------------------------------------------------------
// Fake email provider
//
// Local to this file rather than the shared mock package: that package implements this
// package's interface, so importing it from here would be an import cycle.
// ---------------------------------------------------------------------------

// fakeAvatars records what would have been stored, so the service's decisions can be
// checked without touching a disk.
type fakeAvatars struct {
	stored  map[string][]byte
	removed []string
	err     error
}

func (f *fakeAvatars) Put(_ context.Context, userID, _ string, data []byte) (string, error) {
	if f.err != nil {
		return "", f.err
	}
	if f.stored == nil {
		f.stored = map[string][]byte{}
	}
	url := "/media/avatars/" + userID + ".png"
	f.stored[url] = data
	return url, nil
}

func (f *fakeAvatars) Remove(_ context.Context, url string) error {
	f.removed = append(f.removed, url)
	delete(f.stored, url)
	return nil
}

type fakeEmail struct {
	sent []EmailMessage
	err  error
}

func (f *fakeEmail) Name() string { return "fake" }

func (f *fakeEmail) Send(_ context.Context, msg EmailMessage) error {
	if f.err != nil {
		return f.err
	}
	f.sent = append(f.sent, msg)
	return nil
}

func (f *fakeEmail) Last() (EmailMessage, bool) {
	if len(f.sent) == 0 {
		return EmailMessage{}, false
	}
	return f.sent[len(f.sent)-1], true
}

// ---------------------------------------------------------------------------
// Fake Google verifier
// ---------------------------------------------------------------------------

type fakeGoogle struct {
	identity GoogleIdentity
	err      error
}

func (f *fakeGoogle) Verify(context.Context, string) (GoogleIdentity, error) {
	if f.err != nil {
		return GoogleIdentity{}, f.err
	}
	return f.identity, nil
}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

func newService(t *testing.T) (*Service, *fakeRepo, *fakeEmail) {
	t.Helper()
	svc, repo, mail, _ := newServiceWithGoogle(t, nil)
	return svc, repo, mail
}

func newServiceWithGoogle(t *testing.T, google GoogleTokenVerifier) (
	*Service, *fakeRepo, *fakeEmail, *fakeGoogle) {
	t.Helper()
	repo := newFakeRepo()
	mail := &fakeEmail{}
	issuer, err := jwt.NewIssuer("test-signing-secret", 15*time.Minute)
	if err != nil {
		t.Fatalf("issuer: %v", err)
	}
	log := slog.New(slog.NewTextHandler(io.Discard, nil))
	fake, _ := google.(*fakeGoogle)
	return NewService(repo, issuer, mail, google, &fakeAvatars{}, DefaultPolicy(), log),
		repo, mail, fake
}

func codeOf(t *testing.T, err error) apperr.Code {
	t.Helper()
	var e *apperr.AppError
	if !errors.As(err, &e) {
		t.Fatalf("expected an AppError, got %v", err)
	}
	return e.Code
}

// ---------------------------------------------------------------------------
// Email verification
// ---------------------------------------------------------------------------

func TestStartEmailVerification_SendsACode(t *testing.T) {
	svc, _, mail := newService(t)

	if err := svc.StartEmailVerification(context.Background(), "New@Voca.dev"); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	msg, sent := mail.Last()
	if !sent {
		t.Fatal("a code email must be sent")
	}
	// The address is normalized before anything else touches it, so a capitalised address
	// and a lowercase one are the same account.
	if msg.To != "new@voca.dev" {
		t.Errorf("recipient = %q, want the lowercased address", msg.To)
	}
	if msg.Template != TemplateSignupCode {
		t.Errorf("template = %q", msg.Template)
	}
}

// An address that already has an account is told so, so the app can send the person to
// sign in instead of leaving them waiting for a code that will never arrive.
func TestStartEmailVerification_SaysWhenTheAddressIsTaken(t *testing.T) {
	svc, repo, mail := newService(t)
	repo.addUser("taken@voca.dev", "password123")

	err := svc.StartEmailVerification(context.Background(), "taken@voca.dev")
	if got := codeOf(t, err); got != apperr.CodeEmailAlreadyExists {
		t.Fatalf("got %s, want EMAIL_ALREADY_EXISTS", got)
	}

	// No code is issued, whatever the answer says.
	msg, sent := mail.Last()
	if !sent {
		t.Fatal("the address should also be told by email")
	}
	if msg.Template != TemplateAccountExists {
		t.Errorf("template = %q, want the account-exists notice", msg.Template)
	}
	// Whoever typed the address may not own it, so the message must carry nothing that
	// would let them in.
	if _, hasCode := msg.Params["code"]; hasCode {
		t.Error("the account-exists notice must not carry a verification code")
	}
}

// Somebody who did not try to sign up should still learn that an attempt was made, but a
// failure to tell them must not change what the app is told.
func TestStartEmailVerification_TakenAddressAnswersTheSameIfTheNoticeFails(t *testing.T) {
	svc, repo, mail := newService(t)
	repo.addUser("taken@voca.dev", "password123")
	mail.err = errors.New("provider is down")

	err := svc.StartEmailVerification(context.Background(), "taken@voca.dev")
	if got := codeOf(t, err); got != apperr.CodeEmailAlreadyExists {
		t.Fatalf("got %s, want EMAIL_ALREADY_EXISTS even when the notice fails", got)
	}
}

func TestStartEmailVerification_RejectsMalformedAddress(t *testing.T) {
	svc, _, _ := newService(t)

	for _, bad := range []string{"", "   ", "not-an-email", "@voca.dev", "a b@voca.dev"} {
		err := svc.StartEmailVerification(context.Background(), bad)
		if got := codeOf(t, err); got != apperr.CodeInvalidEmail {
			t.Errorf("%q gave %s, want INVALID_EMAIL", bad, got)
		}
	}
}

func TestStartEmailVerification_RateLimitsResends(t *testing.T) {
	svc, _, _ := newService(t)
	ctx := context.Background()

	policy := DefaultPolicy()
	for i := 0; i < policy.ResendMaxInWindow; i++ {
		if err := svc.StartEmailVerification(ctx, "spam@voca.dev"); err != nil {
			t.Fatalf("request %d should succeed: %v", i+1, err)
		}
	}

	err := svc.StartEmailVerification(ctx, "spam@voca.dev")
	if got := codeOf(t, err); got != apperr.CodeTooManyRequests {
		t.Fatalf("got %s, want TOO_MANY_REQUESTS", got)
	}
}

func TestVerifyCode_AcceptsTheCorrectCode(t *testing.T) {
	svc, repo, _ := newService(t)
	repo.addVerification("a@voca.dev", PurposeSignup, "123456",
		time.Now().Add(time.Minute), 0, false)

	if err := svc.VerifyCode(context.Background(), "a@voca.dev", PurposeSignup, "123456"); err != nil {
		t.Fatalf("the correct code must verify: %v", err)
	}
}

func TestVerifyCode_RejectsAWrongCodeAndCountsTheAttempt(t *testing.T) {
	svc, repo, _ := newService(t)
	repo.addVerification("a@voca.dev", PurposeSignup, "123456",
		time.Now().Add(time.Minute), 0, false)

	err := svc.VerifyCode(context.Background(), "a@voca.dev", PurposeSignup, "000000")
	if got := codeOf(t, err); got != apperr.CodeInvalidCode {
		t.Fatalf("got %s, want INVALID_VERIFICATION_CODE", got)
	}
	if repo.verifications[0].Attempts != 1 {
		t.Errorf("attempts = %d, want 1", repo.verifications[0].Attempts)
	}
}

func TestVerifyCode_RejectsAnExpiredCode(t *testing.T) {
	svc, repo, _ := newService(t)
	repo.addVerification("a@voca.dev", PurposeSignup, "123456",
		time.Now().Add(-time.Minute), 0, false)

	err := svc.VerifyCode(context.Background(), "a@voca.dev", PurposeSignup, "123456")
	if got := codeOf(t, err); got != apperr.CodeCodeExpired {
		t.Fatalf("got %s, want VERIFICATION_CODE_EXPIRED", got)
	}
}

// The attempt cap is what makes a six-digit code safe: a million guesses is nothing, five
// is a wall.
func TestVerifyCode_StopsAfterTheAttemptLimit(t *testing.T) {
	svc, repo, _ := newService(t)
	repo.addVerification("a@voca.dev", PurposeSignup, "123456",
		time.Now().Add(time.Minute), 5, false)

	err := svc.VerifyCode(context.Background(), "a@voca.dev", PurposeSignup, "123456")
	if got := codeOf(t, err); got != apperr.CodeTooManyAttempts {
		t.Fatalf("even the correct code must be refused once exhausted, got %s", got)
	}
}

// A signup code must not open a password reset.
func TestVerifyCode_PurposesAreNotInterchangeable(t *testing.T) {
	svc, repo, _ := newService(t)
	repo.addVerification("a@voca.dev", PurposeSignup, "123456",
		time.Now().Add(time.Minute), 0, false)

	err := svc.VerifyCode(context.Background(), "a@voca.dev", PurposePasswordReset, "123456")
	if got := codeOf(t, err); got != apperr.CodeInvalidCode {
		t.Fatalf("a signup code must not verify a reset, got %s", got)
	}
}

// ---------------------------------------------------------------------------
// Registration
// ---------------------------------------------------------------------------

func validRegistration() RegisterInput {
	level, goal, phone := "B1", "pronunciation", "+998901234567"
	return RegisterInput{
		Email: "new@voca.dev", Password: "password123",
		FirstName: "Sam", LastName: "Hodiev", Phone: &phone,
		CEFRLevel: &level, LearningGoal: &goal,
	}
}

func TestRegister_RequiresAVerifiedAddress(t *testing.T) {
	svc, _, _ := newService(t)

	_, err := svc.Register(context.Background(), validRegistration())
	if got := codeOf(t, err); got != apperr.CodeEmailNotVerified {
		t.Fatalf("got %s, want ACCOUNT_NOT_VERIFIED", got)
	}
}

func TestRegister_SucceedsAfterVerificationAndReturnsASession(t *testing.T) {
	svc, repo, _ := newService(t)
	repo.addVerification("new@voca.dev", PurposeSignup, "123456",
		time.Now().Add(time.Minute), 0, true)

	session, err := svc.Register(context.Background(), validRegistration())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	// Registration signs the person in directly: asking them to log in immediately after
	// creating an account is friction with no security benefit.
	if session.AccessToken == "" || session.RefreshToken == "" {
		t.Error("registration must establish a session")
	}
	if session.ExpiresIn <= 0 {
		t.Error("the session must report when the access token expires")
	}
}

func TestRegister_RejectsADuplicateAddress(t *testing.T) {
	svc, repo, _ := newService(t)
	repo.addUser("new@voca.dev", "password123")
	repo.addVerification("new@voca.dev", PurposeSignup, "123456",
		time.Now().Add(time.Minute), 0, true)

	_, err := svc.Register(context.Background(), validRegistration())
	if got := codeOf(t, err); got != apperr.CodeEmailAlreadyExists {
		t.Fatalf("got %s, want EMAIL_ALREADY_EXISTS", got)
	}
}

func TestRegister_RejectsAShortPassword(t *testing.T) {
	svc, repo, _ := newService(t)
	repo.addVerification("new@voca.dev", PurposeSignup, "123456",
		time.Now().Add(time.Minute), 0, true)

	in := validRegistration()
	in.Password = "short"

	_, err := svc.Register(context.Background(), in)
	if got := codeOf(t, err); got != apperr.CodeInvalidPassword {
		t.Fatalf("got %s, want INVALID_PASSWORD", got)
	}
}

func TestRegister_RejectsAnUnknownLevelOrGoal(t *testing.T) {
	svc, repo, _ := newService(t)
	repo.addVerification("new@voca.dev", PurposeSignup, "123456",
		time.Now().Add(time.Minute), 0, true)

	bad := "Z9"
	in := validRegistration()
	in.CEFRLevel = &bad

	_, err := svc.Register(context.Background(), in)
	if got := codeOf(t, err); got != apperr.CodeValidation {
		t.Fatalf("got %s, want VALIDATION_ERROR", got)
	}
}

func TestRegister_RequiresAName(t *testing.T) {
	svc, repo, _ := newService(t)
	repo.addVerification("new@voca.dev", PurposeSignup, "123456",
		time.Now().Add(time.Minute), 0, true)

	in := validRegistration()
	in.FirstName = "  "

	if _, err := svc.Register(context.Background(), in); codeOf(t, err) != apperr.CodeValidation {
		t.Fatal("a blank first name must be rejected")
	}
}

// ---------------------------------------------------------------------------
// Login
// ---------------------------------------------------------------------------

func TestLogin_SucceedsWithTheCorrectPassword(t *testing.T) {
	svc, repo, _ := newService(t)
	repo.addUser("a@voca.dev", "password123")

	session, err := svc.Login(context.Background(), "a@voca.dev", "password123")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if session.AccessToken == "" {
		t.Error("login must return an access token")
	}
}

// A wrong password and an unknown address must be indistinguishable, or the endpoint
// becomes a way to enumerate accounts.
func TestLogin_GivesTheSameAnswerForWrongPasswordAndUnknownAddress(t *testing.T) {
	svc, repo, _ := newService(t)
	repo.addUser("a@voca.dev", "password123")

	_, wrongPassword := svc.Login(context.Background(), "a@voca.dev", "wrongpassword")
	_, unknown := svc.Login(context.Background(), "nobody@voca.dev", "password123")

	if codeOf(t, wrongPassword) != apperr.CodeInvalidCredentials {
		t.Error("a wrong password must give INVALID_CREDENTIALS")
	}
	if codeOf(t, unknown) != apperr.CodeInvalidCredentials {
		t.Error("an unknown address must give INVALID_CREDENTIALS")
	}
	if wrongPassword.Error() != unknown.Error() {
		t.Errorf("the two answers must be identical:\n  %v\n  %v", wrongPassword, unknown)
	}
}

// A guest has no password, so a password login against a guest account must fail.
func TestLogin_RejectsAnAccountWithNoPassword(t *testing.T) {
	svc, repo, _ := newService(t)
	repo.addUser("guest@voca.dev", "")

	_, err := svc.Login(context.Background(), "guest@voca.dev", "anything123")
	if codeOf(t, err) != apperr.CodeInvalidCredentials {
		t.Fatal("an account without a password must not accept one")
	}
}

// ---------------------------------------------------------------------------
// Password reset
// ---------------------------------------------------------------------------

func TestResetPassword_ChangesThePasswordAndEndsOtherSessions(t *testing.T) {
	svc, repo, _ := newService(t)
	user := repo.addUser("a@voca.dev", "oldpassword")
	repo.addVerification("a@voca.dev", PurposePasswordReset, "123456",
		time.Now().Add(time.Minute), 0, true)

	// An existing session, which the reset must invalidate.
	repo.refresh["existing"] = refreshRow{id: uuid.New(), userID: user.ID,
		expiresAt: time.Now().Add(time.Hour)}

	if _, err := svc.ResetPassword(context.Background(), "a@voca.dev", "newpassword1"); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if _, err := svc.Login(context.Background(), "a@voca.dev", "newpassword1"); err != nil {
		t.Error("the new password must work")
	}
	if _, err := svc.Login(context.Background(), "a@voca.dev", "oldpassword"); err == nil {
		t.Error("the old password must stop working")
	}
	// A reset usually means the old session was compromised, so leaving other devices
	// signed in would defeat the point.
	if !repo.refresh["existing"].revoked {
		t.Error("existing sessions must be revoked by a password reset")
	}
}

func TestResetPassword_RequiresAVerifiedCode(t *testing.T) {
	svc, repo, _ := newService(t)
	repo.addUser("a@voca.dev", "oldpassword")
	repo.addVerification("a@voca.dev", PurposePasswordReset, "123456",
		time.Now().Add(time.Minute), 0, false) // not verified

	_, err := svc.ResetPassword(context.Background(), "a@voca.dev", "newpassword1")
	if codeOf(t, err) != apperr.CodeInvalidCode {
		t.Fatal("resetting without a verified code must be refused")
	}
}

func TestStartPasswordReset_SilentForUnknownAddress(t *testing.T) {
	svc, _, mail := newService(t)

	if err := svc.StartPasswordReset(context.Background(), "nobody@voca.dev"); err != nil {
		t.Fatalf("the response must not differ: %v", err)
	}
	if _, sent := mail.Last(); sent {
		t.Fatal("no email may be sent for an address with no account")
	}
}

// ---------------------------------------------------------------------------
// Sessions
// ---------------------------------------------------------------------------

func TestRefresh_RotatesTheToken(t *testing.T) {
	svc, repo, _ := newService(t)
	repo.addUser("a@voca.dev", "password123")

	first, err := svc.Login(context.Background(), "a@voca.dev", "password123")
	if err != nil {
		t.Fatalf("login: %v", err)
	}

	second, err := svc.Refresh(context.Background(), first.RefreshToken)
	if err != nil {
		t.Fatalf("refresh: %v", err)
	}
	if second.RefreshToken == first.RefreshToken {
		t.Error("refreshing must issue a new refresh token, not reuse the old one")
	}
}

// Presenting a token that was already rotated means it was replayed, so it was probably
// stolen. Every session for that account ends.
func TestRefresh_ReuseRevokesEverySession(t *testing.T) {
	svc, repo, _ := newService(t)
	repo.addUser("a@voca.dev", "password123")

	first, _ := svc.Login(context.Background(), "a@voca.dev", "password123")
	second, _ := svc.Refresh(context.Background(), first.RefreshToken)

	// Replay the retired token.
	if _, err := svc.Refresh(context.Background(), first.RefreshToken); codeOf(t, err) != apperr.CodeSessionExpired {
		t.Fatal("a replayed token must be refused")
	}

	// The token issued legitimately must now be dead too.
	if _, err := svc.Refresh(context.Background(), second.RefreshToken); err == nil {
		t.Error("reuse detection must revoke the whole family, including the live token")
	}
}

func TestRefresh_RejectsAnUnknownToken(t *testing.T) {
	svc, _, _ := newService(t)

	_, err := svc.Refresh(context.Background(), "not-a-real-token")
	if codeOf(t, err) != apperr.CodeSessionExpired {
		t.Fatal("an unknown refresh token must be refused")
	}
}

// Logging out with a token we do not recognise is not an error: the caller wanted to be
// signed out and now is.
func TestLogout_IsForgivingOfAnUnknownToken(t *testing.T) {
	svc, _, _ := newService(t)

	if err := svc.Logout(context.Background(), "not-a-real-token"); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

// ---------------------------------------------------------------------------
// Preferences
// ---------------------------------------------------------------------------

func TestSavePreferences_RejectsUnknownValues(t *testing.T) {
	svc, repo, _ := newService(t)
	user := repo.addUser("a@voca.dev", "password123")

	badLevel := "Z9"
	if err := svc.SavePreferences(context.Background(), user.ID,
		Preferences{CEFRLevel: &badLevel}); codeOf(t, err) != apperr.CodeValidation {
		t.Error("an unknown level must be refused")
	}

	badGoal := "become-fluent-overnight"
	if err := svc.SavePreferences(context.Background(), user.ID,
		Preferences{LearningGoal: &badGoal}); codeOf(t, err) != apperr.CodeValidation {
		t.Error("an unknown goal must be refused")
	}

	if err := svc.SavePreferences(context.Background(), user.ID,
		Preferences{DailyGoalWords: 5000}); codeOf(t, err) != apperr.CodeValidation {
		t.Error("an out-of-range daily goal must be refused")
	}
}

func TestSavePreferences_AcceptsEveryDocumentedValue(t *testing.T) {
	svc, repo, _ := newService(t)
	user := repo.addUser("a@voca.dev", "password123")

	for level := range ValidLevels {
		l := level
		if err := svc.SavePreferences(context.Background(), user.ID,
			Preferences{CEFRLevel: &l}); err != nil {
			t.Errorf("level %s must be accepted: %v", l, err)
		}
	}
	for goal := range ValidGoals {
		g := goal
		if err := svc.SavePreferences(context.Background(), user.ID,
			Preferences{LearningGoal: &g}); err != nil {
			t.Errorf("goal %s must be accepted: %v", g, err)
		}
	}
}

// ---------------------------------------------------------------------------
// Secret hygiene
// ---------------------------------------------------------------------------

// The code exists in the recipient's inbox and nowhere else we control.
func TestVerificationCodeIsNeverReturnedToTheCaller(t *testing.T) {
	svc, _, mail := newService(t)

	if err := svc.StartEmailVerification(context.Background(), "a@voca.dev"); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	msg, _ := mail.Last()
	code := msg.Params["code"]
	if code == "" {
		t.Fatal("the email must carry a code")
	}
	if len(code) != DefaultPolicy().CodeLength || strings.ContainsAny(code, "abcdefABCDEF") {
		t.Errorf("code = %q, want %d digits", code, DefaultPolicy().CodeLength)
	}
}

// ---------------------------------------------------------------------------
// Google sign-in
// ---------------------------------------------------------------------------

func TestSignInWithGoogle_CreatesAnAccountOnFirstUse(t *testing.T) {
	google := &fakeGoogle{identity: GoogleIdentity{
		Subject: "google-subject-1", Email: "new@voca.dev", EmailVerified: true,
	}}
	svc, repo, _, _ := newServiceWithGoogle(t, google)
	repo.nextEmail = "new@voca.dev"

	session, err := svc.SignInWithGoogle(context.Background(), "any-token", RegisterInput{})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if session.AccessToken == "" {
		t.Error("Google sign-in must establish a session")
	}
}

// Someone who signed up by email and later taps Google is the same person. Creating a
// second account would split their practice history in two.
func TestSignInWithGoogle_LinksToAnExistingEmailAccount(t *testing.T) {
	google := &fakeGoogle{identity: GoogleIdentity{
		Subject: "google-subject-1", Email: "a@voca.dev", EmailVerified: true,
	}}
	svc, repo, _, _ := newServiceWithGoogle(t, google)
	existing := repo.addUser("a@voca.dev", "password123")

	session, err := svc.SignInWithGoogle(context.Background(), "any-token", RegisterInput{})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if session.User.ID != existing.ID {
		t.Error("Google must sign in to the existing account, not create a second one")
	}
	if repo.users["a@voca.dev"].ExternalAuthID == nil {
		t.Error("the Google subject must be linked to the account")
	}
}

// An unverified Google address would let someone claim an address they do not control.
func TestSignInWithGoogle_RefusesAnUnverifiedAddress(t *testing.T) {
	google := &fakeGoogle{identity: GoogleIdentity{
		Subject: "s", Email: "a@voca.dev", EmailVerified: false,
	}}
	svc, _, _, _ := newServiceWithGoogle(t, google)

	_, err := svc.SignInWithGoogle(context.Background(), "any-token", RegisterInput{})
	if codeOf(t, err) != apperr.CodeEmailNotVerified {
		t.Fatalf("got %s, want ACCOUNT_NOT_VERIFIED", codeOf(t, err))
	}
}

func TestSignInWithGoogle_RejectsABadToken(t *testing.T) {
	google := &fakeGoogle{err: errors.New("token rejected")}
	svc, _, _, _ := newServiceWithGoogle(t, google)

	_, err := svc.SignInWithGoogle(context.Background(), "forged", RegisterInput{})
	if codeOf(t, err) != apperr.CodeInvalidCredentials {
		t.Fatalf("got %s, want INVALID_CREDENTIALS", codeOf(t, err))
	}
}

// With no verifier configured the endpoint reports itself unavailable rather than
// pretending to work.
func TestSignInWithGoogle_UnavailableWhenNotConfigured(t *testing.T) {
	svc, _, _ := newService(t)

	_, err := svc.SignInWithGoogle(context.Background(), "any-token", RegisterInput{})
	if codeOf(t, err) != apperr.CodeProviderUnavailable {
		t.Fatalf("got %s, want PROVIDER_UNAVAILABLE", codeOf(t, err))
	}
}

// A phone number is required, and the same number written in different ways has to end up
// as one value. Otherwise "+998 90 123 45 67" and "998901234567" are two different people
// as far as the database is concerned.
func TestNormalizePhone(t *testing.T) {
	ok := map[string]string{
		"+998 90 123 45 67": "+998901234567",
		"998901234567":      "+998901234567",
		"(90) 123-45-67":    "+998901234567",
		"901234567":         "+998901234567",
		"0901234567":        "+998901234567",
		"+1 415 555 0132":   "+14155550132",
	}
	for input, want := range ok {
		got, err := normalizePhone(&input)
		if err != nil {
			t.Errorf("%q returned %v, want it accepted", input, err)
			continue
		}
		if got != want {
			t.Errorf("%q became %q, want %q", input, got, want)
		}
	}

	bad := []string{"", "   ", "abc", "12345", "+998 90 123 45 67 89 01 23"}
	for _, input := range bad {
		if _, err := normalizePhone(&input); err == nil {
			t.Errorf("%q was accepted, want it rejected", input)
		}
	}

	if _, err := normalizePhone(nil); err == nil {
		t.Error("a missing phone number must be rejected")
	}
}

// The rule lives on the server, so a client that simply omits the field cannot skip it.
func TestRegister_RequiresAPhoneNumber(t *testing.T) {
	svc, repo, _ := newService(t)
	repo.addVerification("new@voca.dev", PurposeSignup, "123456",
		time.Now().Add(time.Minute), 0, true)

	in := validRegistration()
	in.Phone = nil

	_, err := svc.Register(context.Background(), in)
	if got := codeOf(t, err); got != apperr.CodeValidation {
		t.Fatalf("registering with no phone gave %s, want VALIDATION_ERROR", got)
	}
}

func TestSaveAvatar_StoresAndPointsTheProfileAtIt(t *testing.T) {
	svc, repo, _ := newService(t)
	id := uuid.New()

	url, err := svc.SaveAvatar(context.Background(), id, "image/png", []byte("bytes"))
	if err != nil {
		t.Fatalf("SaveAvatar: %v", err)
	}
	if url == "" {
		t.Fatal("a url should be returned")
	}
	stored, err := repo.AvatarURL(context.Background(), id)
	if err != nil {
		t.Fatalf("AvatarURL: %v", err)
	}
	if stored != url {
		t.Errorf("profile points at %q, want %q", stored, url)
	}
}

// Replacing a picture should not leave the old file behind forever.
func TestSaveAvatar_RemovesThePreviousPicture(t *testing.T) {
	svc, repo, _ := newService(t)
	id := uuid.New()
	ctx := context.Background()

	if err := repo.SetAvatarURL(ctx, id, "/media/avatars/old.png"); err != nil {
		t.Fatalf("seed: %v", err)
	}

	if _, err := svc.SaveAvatar(ctx, id, "image/png", []byte("bytes")); err != nil {
		t.Fatalf("SaveAvatar: %v", err)
	}

	store := svc.avatars.(*fakeAvatars)
	if len(store.removed) != 1 || store.removed[0] != "/media/avatars/old.png" {
		t.Errorf("removed = %v, want the previous picture", store.removed)
	}
}

// A rejected image is the person's problem to fix, so it must come back as a validation
// error they can act on rather than as an internal failure.
func TestSaveAvatar_RejectedImageIsAValidationError(t *testing.T) {
	svc, _, _ := newService(t)
	svc.avatars.(*fakeAvatars).err = errors.New("not an accepted image type")

	_, err := svc.SaveAvatar(context.Background(), uuid.New(), "image/png", []byte("x"))
	if got := codeOf(t, err); got != apperr.CodeValidation {
		t.Fatalf("got %s, want VALIDATION_ERROR", got)
	}
}

// The profile is built from the token's signed claims, never from the request body. A
// client can send any name it likes, and believing it would let somebody sign in as one
// identity while presenting somebody else's details.
func TestSplitDisplayName(t *testing.T) {
	cases := map[string][2]string{
		"Samandar Xodiev":        {"Samandar", "Xodiev"},
		"Samandar":               {"Samandar", ""},
		"Samandar Alisher Ogli":  {"Samandar", "Alisher Ogli"},
		"":                       {"", ""},
		"   ":                    {"", ""},
		"  Samandar   Xodiev   ": {"Samandar", "Xodiev"},
	}
	for input, want := range cases {
		first, last := splitDisplayName(input)
		if first != want[0] || last != want[1] {
			t.Errorf("%q -> (%q, %q), want (%q, %q)", input, first, last, want[0], want[1])
		}
	}
}

// Somebody who keeps typing a registered address into sign-up must not be able to make
// Voca mail its owner over and over. The answer to the app stays the same either way, so
// the throttle cannot be observed from outside.
func TestStartEmailVerification_NoticeIsSentOncePerWindow(t *testing.T) {
	svc, repo, mail := newService(t)
	repo.addUser("taken@voca.dev", "password123")

	for i := 0; i < 5; i++ {
		err := svc.StartEmailVerification(context.Background(), "taken@voca.dev")
		if got := codeOf(t, err); got != apperr.CodeEmailAlreadyExists {
			t.Fatalf("attempt %d gave %s, want EMAIL_ALREADY_EXISTS every time", i+1, got)
		}
	}

	notices := 0
	for _, m := range mail.sent {
		if m.Template == TemplateAccountExists {
			notices++
		}
	}
	if notices != 1 {
		t.Fatalf("sent %d notices for five attempts, want exactly one", notices)
	}
}

func TestNoticeThrottleWindow(t *testing.T) {
	var th noticeThrottle
	now := time.Now()
	window := 15 * time.Minute

	if !th.allow("a@b.com", now, window) {
		t.Fatal("the first notice should be allowed")
	}
	if th.allow("a@b.com", now.Add(time.Minute), window) {
		t.Fatal("a second notice inside the window should be refused")
	}
	if !th.allow("other@b.com", now.Add(time.Minute), window) {
		t.Fatal("a different address must not be affected")
	}
	if !th.allow("a@b.com", now.Add(window+time.Second), window) {
		t.Fatal("a notice after the window should be allowed again")
	}
}

// A Google or guest account has no password. Trying one with a password must look exactly
// like a wrong password, not like an error, and not like an instant refusal.
func TestLogin_AccountWithoutAPasswordIsJustWrongCredentials(t *testing.T) {
	svc, repo, _ := newService(t)
	repo.addUser("social@voca.dev", "unused")
	u, _ := repo.UserByEmail(context.Background(), "social@voca.dev")
	delete(repo.hashes, u.ID) // what a Google-created account looks like

	_, err := svc.Login(context.Background(), "social@voca.dev", "anything123")
	if got := codeOf(t, err); got != apperr.CodeInvalidCredentials {
		t.Fatalf("got %s, want INVALID_CREDENTIALS", got)
	}
}

// Me gathers the account, the profile and the preferences in one answer, because every
// screen that shows one of them shows the others.
func TestMe_ReturnsAccountProfileAndPreferences(t *testing.T) {
	svc, repo, _ := newService(t)
	repo.addUser("me@voca.dev", "password123")
	u, _ := repo.UserByEmail(context.Background(), "me@voca.dev")

	first, last, avatar := "Samandar", "Xodiev", "/media/avatars/x.png"
	repo.profiles = map[uuid.UUID]ProfileInfo{
		u.ID: {FirstName: &first, LastName: &last, AvatarURL: &avatar},
	}

	me, err := svc.Me(context.Background(), u.ID)
	if err != nil {
		t.Fatalf("Me: %v", err)
	}
	if me.User.ID != u.ID {
		t.Errorf("user = %v, want %v", me.User.ID, u.ID)
	}
	if me.Profile.FirstName == nil || *me.Profile.FirstName != "Samandar" {
		t.Errorf("first name = %v", me.Profile.FirstName)
	}
	if me.Profile.AvatarURL == nil || *me.Profile.AvatarURL != avatar {
		t.Errorf("avatar = %v", me.Profile.AvatarURL)
	}
}

// A guest has no profile row. That is normal and must not fail the request.
func TestMe_MissingProfileIsNotAnError(t *testing.T) {
	svc, repo, _ := newService(t)
	repo.addUser("guest@voca.dev", "password123")
	u, _ := repo.UserByEmail(context.Background(), "guest@voca.dev")

	me, err := svc.Me(context.Background(), u.ID)
	if err != nil {
		t.Fatalf("Me: %v", err)
	}
	if me.Profile.FirstName != nil {
		t.Errorf("expected no first name, got %v", *me.Profile.FirstName)
	}
}

// A token for an account that no longer exists is a signed-out person, not a server error.
func TestMe_UnknownUserIsUnauthenticated(t *testing.T) {
	svc, _, _ := newService(t)
	_, err := svc.Me(context.Background(), uuid.New())
	if got := codeOf(t, err); got != apperr.CodeUnauthenticated {
		t.Fatalf("got %s, want UNAUTHENTICATED", got)
	}
}

// ---------------------------------------------------------------------------
// Confirmed sign-out
// ---------------------------------------------------------------------------

func TestStartSignOut_SendsTheCodeToTheAccountsOwnAddress(t *testing.T) {
	svc, repo, mail := newService(t)
	u := repo.addUser("ali@example.com", "correct horse battery")

	if err := svc.StartSignOut(context.Background(), u.ID, "  Ali@Example.com "); err != nil {
		t.Fatalf("start: %v", err)
	}
	msg, ok := mail.Last()
	if !ok || msg.Template != TemplateSignOutCode || msg.To != "ali@example.com" {
		t.Fatalf("expected a sign-out code to the account, got %+v", msg)
	}
	if len(msg.Params["code"]) != DefaultPolicy().CodeLength {
		t.Fatalf("code has the wrong length: %q", msg.Params["code"])
	}
}

func TestStartSignOut_RefusesAnotherAddressAndSendsNothing(t *testing.T) {
	svc, repo, mail := newService(t)
	u := repo.addUser("ali@example.com", "correct horse battery")

	err := svc.StartSignOut(context.Background(), u.ID, "someone@example.com")
	if codeOf(t, err) != apperr.CodeEmailMismatch {
		t.Fatalf("expected EMAIL_MISMATCH, got %v", err)
	}
	if len(mail.sent) != 0 {
		t.Fatalf("nothing should be sent, got %d messages", len(mail.sent))
	}
}

func TestStartSignOut_GuestHasNoAddressToConfirmFrom(t *testing.T) {
	svc, repo, mail := newService(t)
	guest, err := svc.CreateGuest(context.Background(), RegisterInput{})
	if err != nil {
		t.Fatalf("guest: %v", err)
	}
	// The fake only records accounts that have an address; the real table keeps guests
	// too, with no email. Seed it the way the database would hold it.
	repo.users["guest:"+guest.User.ID.String()] = guest.User

	err = svc.StartSignOut(context.Background(), guest.User.ID, "any@example.com")
	if codeOf(t, err) != apperr.CodeValidation {
		t.Fatalf("expected a validation error, got %v", err)
	}
	if len(mail.sent) != 0 {
		t.Fatal("nothing should be sent to a guest")
	}
}

func TestConfirmSignOut_RevokesTheSessionOnlyWithTheRightCode(t *testing.T) {
	ctx := context.Background()
	svc, repo, mail := newService(t)
	u := repo.addUser("ali@example.com", "correct horse battery")
	session, err := svc.Login(ctx, "ali@example.com", "correct horse battery")
	if err != nil {
		t.Fatalf("login: %v", err)
	}
	if err := svc.StartSignOut(ctx, u.ID, "ali@example.com"); err != nil {
		t.Fatalf("start: %v", err)
	}
	msg, _ := mail.Last()
	code := msg.Params["code"]
	wrong := "000000"
	if code == wrong {
		wrong = "111111"
	}
	revoked := func() bool { return repo.refresh[token.Hash(session.RefreshToken)].revoked }

	err = svc.ConfirmSignOut(ctx, u.ID, wrong, session.RefreshToken)
	if codeOf(t, err) != apperr.CodeInvalidCode {
		t.Fatalf("a wrong code must be refused, got %v", err)
	}
	if revoked() {
		t.Fatal("a wrong code must not end the session")
	}

	if err := svc.ConfirmSignOut(ctx, u.ID, code, session.RefreshToken); err != nil {
		t.Fatalf("confirm: %v", err)
	}
	if !revoked() {
		t.Fatal("the right code must end the session")
	}

	// Consumed: the same code cannot confirm a second time.
	err = svc.ConfirmSignOut(ctx, u.ID, code, session.RefreshToken)
	if codeOf(t, err) != apperr.CodeInvalidCode {
		t.Fatalf("a used code must be refused, got %v", err)
	}
}

func TestConfirmSignOut_APasswordResetCodeCannotEndASession(t *testing.T) {
	ctx := context.Background()
	svc, repo, mail := newService(t)
	u := repo.addUser("ali@example.com", "correct horse battery")
	if err := svc.StartPasswordReset(ctx, "ali@example.com"); err != nil {
		t.Fatalf("reset: %v", err)
	}
	msg, _ := mail.Last()

	err := svc.ConfirmSignOut(ctx, u.ID, msg.Params["code"], "whatever")
	if codeOf(t, err) != apperr.CodeInvalidCode {
		t.Fatalf("a code for another purpose must be refused, got %v", err)
	}
}

func TestConfirmSignOut_LeavesAnotherAccountsSessionAlone(t *testing.T) {
	ctx := context.Background()
	svc, repo, mail := newService(t)
	a := repo.addUser("ali@example.com", "correct horse battery")
	repo.addUser("vali@example.com", "correct horse battery")
	other, err := svc.Login(ctx, "vali@example.com", "correct horse battery")
	if err != nil {
		t.Fatalf("login: %v", err)
	}
	if err := svc.StartSignOut(ctx, a.ID, "ali@example.com"); err != nil {
		t.Fatalf("start: %v", err)
	}
	msg, _ := mail.Last()

	if err := svc.ConfirmSignOut(ctx, a.ID, msg.Params["code"], other.RefreshToken); err != nil {
		t.Fatalf("confirm: %v", err)
	}
	if repo.refresh[token.Hash(other.RefreshToken)].revoked {
		t.Fatal("one account must not be able to end another's session")
	}
}
