// The two-pass behaviour, against a stub that answers the way the live service does.
//
// The payloads here are the ones recorded in testdata: a scored pass that found nothing,
// and a reference-free pass that either heard a word or heard nothing. The point being
// guarded is that those two cases stop being indistinguishable, because reporting a
// talking learner as silent sends them off to fix a microphone that works.

package azure

import (
	"context"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"

	"log/slog"

	"github.com/samandar-hodiev/voca/backend/internal/pronunciation"
)

// stub answers the scored pass with `scored` and the reference-free pass with `plain`,
// telling them apart the way Azure does: by the assessment header.
func stub(t *testing.T, scored, plain string) *Provider {
	t.Helper()

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		body := plain
		if r.Header.Get("Pronunciation-Assessment") != "" {
			body = scored
		}
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(body))
	}))
	t.Cleanup(srv.Close)

	p, err := New(Config{Key: "k", Region: "test", Endpoint: srv.URL},
		slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{Level: slog.LevelError})))
	if err != nil {
		t.Fatalf("new provider: %v", err)
	}
	return p
}

func fixture(t *testing.T, name string) string {
	t.Helper()
	b, err := os.ReadFile(filepath.Join("testdata", name))
	if err != nil {
		t.Fatalf("read %s: %v", name, err)
	}
	return string(b)
}

const heardWorld = `{"RecognitionStatus":"Success","DisplayText":"World.",
	"NBest":[{"Display":"World.","Lexical":"world"}]}`

const heardNothing = `{"RecognitionStatus":"Success","DisplayText":"",
	"NBest":[{"Display":"","Lexical":""}]}`

func TestWrongWordIsReportedAsWhatWasHeard(t *testing.T) {
	// The scored pass answers exactly as the live service does for a different word:
	// Success, ".", every score zero, the reference word marked Omission.
	p := stub(t, fixture(t, "assessment_silence.json"), heardWorld)

	out, err := p.AssessPronunciation(context.Background(), pronunciation.AssessmentInput{
		ReferenceText: "think", Language: "en-US",
	})
	if err != nil {
		t.Fatalf("assess: %v", err)
	}

	if len(out.Words) != 0 {
		t.Errorf("words = %d, want none to score", len(out.Words))
	}
	// This is the fix: the service can now say "you said World" instead of "we heard
	// nothing", because the two no longer look the same.
	if out.RecognizedText != "World" {
		t.Errorf("recognized = %q, want World", out.RecognizedText)
	}
}

func TestSilenceStaysSilence(t *testing.T) {
	p := stub(t, fixture(t, "assessment_silence.json"), heardNothing)

	out, err := p.AssessPronunciation(context.Background(), pronunciation.AssessmentInput{
		ReferenceText: "think", Language: "en-US",
	})
	if err != nil {
		t.Fatalf("assess: %v", err)
	}
	if out.RecognizedText != "" {
		t.Errorf("recognized = %q, want empty", out.RecognizedText)
	}
}

func TestScoredAttemptSkipsTheSecondPass(t *testing.T) {
	// A normal attempt must cost exactly one request. The stub fails the test if the
	// reference-free pass is ever reached.
	var calls int
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		calls++
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(fixture(t, "assessment_success.json")))
	}))
	t.Cleanup(srv.Close)

	p, err := New(Config{Key: "k", Region: "test", Endpoint: srv.URL},
		slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{Level: slog.LevelError})))
	if err != nil {
		t.Fatalf("new provider: %v", err)
	}

	out, err := p.AssessPronunciation(context.Background(), pronunciation.AssessmentInput{
		ReferenceText: "think", Language: "en-US",
	})
	if err != nil {
		t.Fatalf("assess: %v", err)
	}
	if len(out.Words) == 0 {
		t.Fatal("expected a scored word")
	}
	if calls != 1 {
		t.Errorf("provider was called %d times, want 1", calls)
	}
}
