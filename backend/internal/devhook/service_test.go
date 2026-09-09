package devhook

import (
	"context"
	"errors"
	"io"
	"log/slog"
	"testing"
)

// fakeNotifier records what would have been delivered. Unit tests NEVER call Telegram:
// the port exists precisely so this substitution is possible (ARCHITECTURE.md 22.1).
type fakeNotifier struct {
	calls []Notification
	err   error
}

func (f *fakeNotifier) Name() string { return "fake" }

func (f *fakeNotifier) Notify(_ context.Context, n Notification) error {
	f.calls = append(f.calls, n)
	return f.err
}

func discardLogger() *slog.Logger {
	return slog.New(slog.NewTextHandler(io.Discard, nil))
}

func sampleEvent() PushEvent {
	return PushEvent{
		Repository:    "samandar-hodiev/voca",
		Branch:        "main",
		Pusher:        "samandar-hodiev",
		CommitCount:   3,
		LatestMessage: "arxitektura skeleti",
		LatestURL:     "https://github.com/samandar-hodiev/voca/commit/abc",
	}
}

func TestHandlePush_DeliversNotification(t *testing.T) {
	notifier := &fakeNotifier{}
	svc := NewService(notifier, discardLogger())

	if err := svc.HandlePush(context.Background(), sampleEvent()); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(notifier.calls) != 1 {
		t.Fatalf("notifier called %d times, want 1", len(notifier.calls))
	}

	got := notifier.calls[0]
	if got.Title != "🚀 New push to Voca" {
		t.Errorf("Title = %q", got.Title)
	}
	if got.Link != "https://github.com/samandar-hodiev/voca/commit/abc" {
		t.Errorf("Link = %q", got.Link)
	}

	want := map[string]string{
		"Repository": "samandar-hodiev/voca",
		"Branch":     "main",
		"Author":     "samandar-hodiev",
		"Commits":    "3",
		"Latest":     "arxitektura skeleti",
	}
	if len(got.Fields) != len(want) {
		t.Fatalf("got %d fields, want %d", len(got.Fields), len(want))
	}
	for _, f := range got.Fields {
		if want[f.Label] != f.Value {
			t.Errorf("field %s = %q, want %q", f.Label, f.Value, want[f.Label])
		}
	}
}

func TestHandlePush_PropagatesNotifierFailure(t *testing.T) {
	notifier := &fakeNotifier{err: errors.New("telegram unreachable")}
	svc := NewService(notifier, discardLogger())

	err := svc.HandlePush(context.Background(), sampleEvent())
	if err == nil {
		t.Fatal("a delivery failure must be reported to the caller")
	}
}

// The commit subject is optional; a push with no commits must still notify.
func TestHandlePush_OmitsLatestFieldWhenNoCommitMessage(t *testing.T) {
	notifier := &fakeNotifier{}
	svc := NewService(notifier, discardLogger())

	ev := sampleEvent()
	ev.LatestMessage = ""
	ev.LatestURL = ""
	ev.CompareURL = "https://github.com/compare"

	if err := svc.HandlePush(context.Background(), ev); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	for _, f := range notifier.calls[0].Fields {
		if f.Label == "Latest" {
			t.Error("Latest field must be omitted when there is no commit message")
		}
	}
	if notifier.calls[0].Link != "https://github.com/compare" {
		t.Error("must fall back to the compare URL when no commit URL exists")
	}
}
