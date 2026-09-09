// Package devhook receives repository events from GitHub and turns them into developer
// notifications.
//
// This is DEVELOPER TOOLING, not part of the Voca learning product. It is kept as its own
// module so it shares nothing with the product modules and can be removed by deleting one
// folder and one route line.
//
// It follows the standard module anatomy from ARCHITECTURE.md 5.4: thin handler, logic in
// the service, and an outbound port that a vendor adapter implements.
package devhook

// PushEvent is our normalized view of a GitHub push.
//
// It deliberately does NOT mirror GitHub's payload shape. Only the fields the
// notification actually needs are carried across the boundary, so a change to GitHub's
// JSON affects the parser and nothing else (ARCHITECTURE.md 7.4).
type PushEvent struct {
	Repository    string
	Branch        string
	Pusher        string
	CommitCount   int
	LatestMessage string
	LatestURL     string
	CompareURL    string
}

// Notification is a provider-neutral message.
//
// The devhook service decides WHAT is said; the adapter decides how it is rendered for
// its transport. No Telegram formatting appears in this package.
type Notification struct {
	Title  string
	Fields []Field
	Link   string
}

// Field is one labelled line in a notification.
type Field struct {
	Label string
	Value string
}
