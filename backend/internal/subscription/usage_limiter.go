// subscription: UsageLimiter — enforces free-tier quota.
//
// Checked by PronunciationService BEFORE the provider call, so a blocked request costs no
// Azure money. This is a COST CONTROL as much as a monetization lever.
//
// MVP counts attempts per user per local day from an indexed column; Stage 2 moves the
// counter to CacheStore (Redis) without changing this interface.
//
// Limits come from configuration (FREE_DAILY_ASSESSMENT_LIMIT), never from literals, so
// pricing experiments do not require a release.
//
// A FAILED attempt must NOT consume quota — we do not charge users for our outages.
//
// See ARCHITECTURE.md 9.4, 6.5, 20.3.
//
// This module owns the POLICY and nothing else: how many attempts a day is, who is exempt
// from it, and when the day rolls over. It deliberately does not count anything, because
// the attempts live in another module's table and reading it from here would couple the
// two (ARCHITECTURE.md 5.5). The caller counts its own rows against the window returned.

package subscription

import (
	"context"
	"log/slog"
	"strings"
	"time"

	"github.com/google/uuid"
)

// Allowance is what one account may do today.
type Allowance struct {
	// Unlimited skips counting entirely.
	Unlimited bool

	// DailyLimit is how many assessed attempts are allowed inside the window.
	DailyLimit int

	// Since is the start of the current local day; ResetsAt is the start of the next one,
	// which is what the app shows as "come back at".
	Since    time.Time
	ResetsAt time.Time
}

// Accounts is the one fact this module needs about a person, and it is deliberately the
// smallest one: the address their account signs in with. Declared here, so subscription
// depends on no other module (ARCHITECTURE.md 7.1, the same pattern as SpeechProvider).
type Accounts interface {
	EmailByID(ctx context.Context, userID uuid.UUID) (string, error)
}

type UsageLimiter struct {
	accounts   Accounts
	dailyLimit int
	unlimited  map[string]struct{}
	location   *time.Location
	now        func() time.Time
	log        *slog.Logger
}

// NewUsageLimiter builds the policy from configuration.
//
// An unparseable timezone falls back to UTC rather than refusing to start: a wrong
// rollover hour is a small problem, and a server that will not boot is a large one.
func NewUsageLimiter(
	accounts Accounts,
	dailyLimit int,
	unlimitedEmails []string,
	timezone string,
	log *slog.Logger,
) *UsageLimiter {
	loc, err := time.LoadLocation(timezone)
	if err != nil {
		log.Warn("usage_limiter_timezone_invalid",
			slog.String("timezone", timezone), slog.String("error", err.Error()))
		loc = time.UTC
	}

	// Addresses are compared case-insensitively because the column is citext: the person
	// who signed up as Samandar@… is the same person as samandar@….
	exempt := make(map[string]struct{}, len(unlimitedEmails))
	for _, e := range unlimitedEmails {
		if key := normalizeEmail(e); key != "" {
			exempt[key] = struct{}{}
		}
	}

	return &UsageLimiter{
		accounts:   accounts,
		dailyLimit: dailyLimit,
		unlimited:  exempt,
		location:   loc,
		now:        time.Now,
		log:        log,
	}
}

// Allowance reports what this account may do for the rest of the local day.
func (l *UsageLimiter) Allowance(ctx context.Context, userID uuid.UUID) (Allowance, error) {
	since, resets := l.window()

	base := Allowance{
		DailyLimit: l.dailyLimit,
		Since:      since,
		ResetsAt:   resets,
	}

	// A limit of zero or less means the limit is switched off entirely.
	if l.dailyLimit <= 0 {
		base.Unlimited = true
		return base, nil
	}

	if len(l.unlimited) == 0 || l.accounts == nil {
		return base, nil
	}

	email, err := l.accounts.EmailByID(ctx, userID)
	if err != nil {
		// Not being able to read an address is no reason to stop somebody practising, but
		// it is also no reason to hand out an exemption. The ordinary limit applies.
		l.log.Warn("usage_limiter_account_lookup_failed",
			slog.String("user_id", userID.String()), slog.String("error", err.Error()))
		return base, nil
	}

	if _, ok := l.unlimited[normalizeEmail(email)]; ok {
		base.Unlimited = true
	}
	return base, nil
}

// window is the current local day, as a half-open interval.
func (l *UsageLimiter) window() (since, resets time.Time) {
	now := l.now().In(l.location)
	since = time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, l.location)
	return since, since.AddDate(0, 0, 1)
}

func normalizeEmail(s string) string {
	return strings.ToLower(strings.TrimSpace(s))
}
