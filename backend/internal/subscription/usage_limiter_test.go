// The quota policy: who is exempt, what the limit is, and when the day turns over.
//
// The exemption is the part worth guarding hardest. It is the only thing standing between
// the person testing the product and being locked out of their own app halfway through a
// session, and it is decided by an address, which is exactly the kind of comparison that
// quietly breaks on capitals or a stray space.

package subscription

import (
	"context"
	"errors"
	"io"
	"log/slog"
	"testing"
	"time"

	"github.com/google/uuid"
)

type fakeAccounts struct {
	email string
	err   error
	calls int
}

func (f *fakeAccounts) EmailByID(context.Context, uuid.UUID) (string, error) {
	f.calls++
	return f.email, f.err
}

func quietLogger() *slog.Logger {
	return slog.New(slog.NewTextHandler(io.Discard, nil))
}

func TestOwnerAddressIsExempt(t *testing.T) {
	accounts := &fakeAccounts{email: "samandarkhodiev04@gmail.com"}
	l := NewUsageLimiter(accounts, 30,
		[]string{"samandarkhodiev04@gmail.com"}, "Asia/Tashkent", quietLogger())

	got, err := l.Allowance(context.Background(), uuid.New())
	if err != nil {
		t.Fatalf("allowance: %v", err)
	}
	if !got.Unlimited {
		t.Error("the exempt address was limited")
	}
}

func TestExemptionIgnoresCaseAndSpacing(t *testing.T) {
	// The column is citext, so these are the same account. A limiter that disagrees
	// would lock the owner out of their own build.
	accounts := &fakeAccounts{email: "  Samandarkhodiev04@Gmail.com "}
	l := NewUsageLimiter(accounts, 30,
		[]string{"samandarkhodiev04@gmail.com"}, "Asia/Tashkent", quietLogger())

	got, _ := l.Allowance(context.Background(), uuid.New())
	if !got.Unlimited {
		t.Error("the same address in different case was treated as a different person")
	}
}

func TestOrdinaryAccountGetsTheDailyLimit(t *testing.T) {
	accounts := &fakeAccounts{email: "learner@example.com"}
	l := NewUsageLimiter(accounts, 30,
		[]string{"samandarkhodiev04@gmail.com"}, "Asia/Tashkent", quietLogger())

	got, err := l.Allowance(context.Background(), uuid.New())
	if err != nil {
		t.Fatalf("allowance: %v", err)
	}
	if got.Unlimited {
		t.Error("an ordinary account was given no limit")
	}
	if got.DailyLimit != 30 {
		t.Errorf("limit = %d, want 30", got.DailyLimit)
	}
	// The window must be a whole local day, ending at the learner's midnight.
	if d := got.ResetsAt.Sub(got.Since); d != 24*time.Hour {
		t.Errorf("window = %v, want 24h", d)
	}
	if h := got.Since.Hour(); h != 0 {
		t.Errorf("window starts at %02d:00, want midnight", h)
	}
}

func TestUnreadableAddressDoesNotGrantAnExemption(t *testing.T) {
	// Failing open here would make the limit optional for anybody who can make a lookup
	// fail. Failing closed on the LIMIT, not on the practice, is the safe direction.
	accounts := &fakeAccounts{err: errors.New("database down")}
	l := NewUsageLimiter(accounts, 30, []string{"owner@example.com"}, "UTC", quietLogger())

	got, err := l.Allowance(context.Background(), uuid.New())
	if err != nil {
		t.Fatalf("a lookup failure must not fail the attempt: %v", err)
	}
	if got.Unlimited {
		t.Error("a failed lookup handed out an exemption")
	}
}

func TestNoExemptionsMeansNoLookupAtAll(t *testing.T) {
	// The common deployment has no exempt accounts. It should not pay for a database
	// read on every single attempt to discover that.
	accounts := &fakeAccounts{email: "learner@example.com"}
	l := NewUsageLimiter(accounts, 30, nil, "UTC", quietLogger())

	if _, err := l.Allowance(context.Background(), uuid.New()); err != nil {
		t.Fatalf("allowance: %v", err)
	}
	if accounts.calls != 0 {
		t.Errorf("looked up the address %d times, want 0", accounts.calls)
	}
}

func TestZeroLimitSwitchesTheQuotaOff(t *testing.T) {
	l := NewUsageLimiter(nil, 0, nil, "UTC", quietLogger())

	got, _ := l.Allowance(context.Background(), uuid.New())
	if !got.Unlimited {
		t.Error("a limit of zero should mean no limit, not no attempts")
	}
}

func TestAnInvalidTimezoneStillStarts(t *testing.T) {
	// A wrong rollover hour is a small problem; a server that will not boot is a large one.
	l := NewUsageLimiter(nil, 30, nil, "Mars/Olympus", quietLogger())
	if l.location != time.UTC {
		t.Errorf("location = %v, want UTC as the fallback", l.location)
	}
}
