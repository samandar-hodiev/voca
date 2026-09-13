// pronunciation: Entitlements — the port for "may this person be assessed right now".
//
// THE CONSUMER OWNS THIS INTERFACE. The subscription module answers it, but nothing in
// this file names that module, so the two can be built, tested and changed separately
// (ARCHITECTURE.md 5.5, 7.1).
//
// The split of responsibility is deliberate. The answer here is POLICY — how many attempts
// a day, who is exempt, when the day rolls over — and policy belongs to subscription. The
// COUNT is not policy: it is this module's own rows in its own table, and reading it from
// another module would couple them for no gain.

package pronunciation

import (
	"context"
	"time"

	"github.com/google/uuid"
)

// Allowance is what one account may do inside the current window.
type Allowance struct {
	Unlimited  bool
	DailyLimit int

	// Since starts the window the attempts are counted in; ResetsAt is when the next one
	// begins, and is what the app shows the learner.
	Since    time.Time
	ResetsAt time.Time
}

type Entitlements interface {
	Allowance(ctx context.Context, userID uuid.UUID) (Allowance, error)
}
