package devhook

import "testing"

const validPushPayload = `{
  "ref": "refs/heads/main",
  "compare": "https://github.com/samandar-hodiev/voca/compare/aaa...bbb",
  "repository": { "full_name": "samandar-hodiev/voca", "name": "voca" },
  "pusher": { "name": "samandar-hodiev" },
  "sender": { "login": "samandar-hodiev" },
  "commits": [
    { "message": "birinchi commit", "url": "https://github.com/x/1" },
    { "message": "ikkinchi commit", "url": "https://github.com/x/2" }
  ],
  "head_commit": {
    "message": "ikkinchi commit\n\nuzun tavsif matni",
    "url": "https://github.com/x/2"
  }
}`

func TestParsePushEvent_ExtractsExpectedFields(t *testing.T) {
	ev, err := ParsePushEvent([]byte(validPushPayload))
	if err != nil {
		t.Fatalf("valid payload must parse: %v", err)
	}

	if ev.Repository != "samandar-hodiev/voca" {
		t.Errorf("Repository = %q", ev.Repository)
	}
	if ev.Branch != "main" {
		t.Errorf("Branch = %q, refs/heads/ prefix must be stripped", ev.Branch)
	}
	if ev.Pusher != "samandar-hodiev" {
		t.Errorf("Pusher = %q", ev.Pusher)
	}
	if ev.CommitCount != 2 {
		t.Errorf("CommitCount = %d, want 2", ev.CommitCount)
	}
	// Only the subject line belongs in a chat notification.
	if ev.LatestMessage != "ikkinchi commit" {
		t.Errorf("LatestMessage = %q, want only the first line", ev.LatestMessage)
	}
	if ev.LatestURL != "https://github.com/x/2" {
		t.Errorf("LatestURL = %q", ev.LatestURL)
	}
}

func TestParsePushEvent_MalformedJSON(t *testing.T) {
	if _, err := ParsePushEvent([]byte(`{"ref": `)); err == nil {
		t.Fatal("malformed JSON must return an error, not a zero value")
	}
}

func TestParsePushEvent_MissingRepositoryIsRejected(t *testing.T) {
	if _, err := ParsePushEvent([]byte(`{"ref":"refs/heads/main"}`)); err == nil {
		t.Fatal("a payload without a repository must be rejected")
	}
}

// head_commit is absent for branch deletions, so the parser must fall back gracefully.
func TestParsePushEvent_FallsBackWhenHeadCommitMissing(t *testing.T) {
	payload := `{
      "ref": "refs/heads/feature",
      "repository": { "full_name": "a/b" },
      "pusher": { "name": "dev" },
      "commits": [ { "message": "oxirgi", "url": "https://github.com/x/9" } ]
    }`

	ev, err := ParsePushEvent([]byte(payload))
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if ev.LatestMessage != "oxirgi" || ev.LatestURL != "https://github.com/x/9" {
		t.Errorf("must fall back to the last commit, got %q / %q", ev.LatestMessage, ev.LatestURL)
	}
}

func TestParsePushEvent_TagRefIsLabelled(t *testing.T) {
	payload := `{"ref":"refs/tags/v1.0.0","repository":{"full_name":"a/b"},"pusher":{"name":"d"}}`
	ev, err := ParsePushEvent([]byte(payload))
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if ev.Branch != "tag: v1.0.0" {
		t.Errorf("Branch = %q, want a tag label", ev.Branch)
	}
}

func TestParsePushEvent_FallsBackToSenderWhenPusherMissing(t *testing.T) {
	payload := `{"ref":"refs/heads/main","repository":{"full_name":"a/b"},"sender":{"login":"bot"}}`
	ev, err := ParsePushEvent([]byte(payload))
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if ev.Pusher != "bot" {
		t.Errorf("Pusher = %q, want the sender login as fallback", ev.Pusher)
	}
}
