// Outbound port for developer notifications.
//
// THE CONSUMER OWNS THIS INTERFACE, not the vendor. Implementations live in
// internal/integrations/telegram (real) and are swapped at wiring time. A different
// transport such as Slack or e-mail would be a new adapter, not a change here
// (ARCHITECTURE.md 7.1, ADR-006).
package devhook

import "context"

// Notifier delivers a notification to whoever is watching the repository.
type Notifier interface {
	// Name identifies the transport, for logging.
	Name() string
	// Notify delivers the message. Implementations must not log secrets.
	Notify(ctx context.Context, n Notification) error
}
