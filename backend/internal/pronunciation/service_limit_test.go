// The quota, enforced where it actually saves money.
//
// The point of checking before the provider call is that a blocked attempt costs nothing.
// A test that only asserted the error would pass even if we called Azure first and threw
// the answer away, so what is counted here is whether the provider was reached at all.

package pronunciation

import (
	"bytes"
	"context"
	"encoding/binary"
	"io"
	"log/slog"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/samandar-hodiev/voca/backend/internal/pronunciation/analysis"
	"github.com/samandar-hodiev/voca/backend/internal/pronunciation/feedback"
	"github.com/samandar-hodiev/voca/backend/internal/pronunciation/scoring"
	"github.com/samandar-hodiev/voca/backend/internal/pronunciation/validation"
	"github.com/samandar-hodiev/voca/backend/internal/shared/apperr"
)

// wav builds a second of silent 16 kHz mono PCM, which is what the app records and what
// the validator expects. Real bytes rather than a stub: the validator parses the header.
func wav(t *testing.T) []byte {
	t.Helper()
	const (
		sampleRate = 16000
		seconds    = 1
		data       = sampleRate * seconds * 2
	)
	b := &bytes.Buffer{}
	b.WriteString("RIFF")
	_ = binary.Write(b, binary.LittleEndian, uint32(36+data))
	b.WriteString("WAVEfmt ")
	_ = binary.Write(b, binary.LittleEndian, uint32(16))
	_ = binary.Write(b, binary.LittleEndian, uint16(1))
	_ = binary.Write(b, binary.LittleEndian, uint16(1))
	_ = binary.Write(b, binary.LittleEndian, uint32(sampleRate))
	_ = binary.Write(b, binary.LittleEndian, uint32(sampleRate*2))
	_ = binary.Write(b, binary.LittleEndian, uint16(2))
	_ = binary.Write(b, binary.LittleEndian, uint16(16))
	b.WriteString("data")
	_ = binary.Write(b, binary.LittleEndian, uint32(data))
	b.Write(make([]byte, data))
	return b.Bytes()
}

type countingProvider struct{ calls int }

func (p *countingProvider) Name() string { return "counting" }

func (p *countingProvider) AssessPronunciation(
	context.Context, AssessmentInput,
) (AssessmentOutput, error) {
	p.calls++
	return AssessmentOutput{
		Provider:       "counting",
		RecognizedText: "think",
		Accuracy:       90, Fluency: 90, Completeness: 100,
		Words: []WordAssessment{{Word: "think", Accuracy: 90, Error: ErrorNone}},
	}, nil
}

type stubRepo struct {
	used  int
	saved int
}

func (r *stubRepo) SaveAttempt(context.Context, Attempt) (uuid.UUID, time.Time, error) {
	r.saved++
	return uuid.New(), time.Now(), nil
}

func (r *stubRepo) RecentAttempts(context.Context, uuid.UUID, int) ([]Attempt, error) {
	return nil, nil
}

func (r *stubRepo) CountAttemptsSince(context.Context, uuid.UUID, time.Time) (int, error) {
	return r.used, nil
}

type fixedAllowance struct{ a Allowance }

func (f fixedAllowance) Allowance(context.Context, uuid.UUID) (Allowance, error) {
	return f.a, nil
}

func newService(repo Repository, provider SpeechProvider, ent Entitlements) *Service {
	return NewService(
		repo, provider,
		scoring.New(scoring.DefaultWeights()),
		analysis.New(analysis.DefaultThresholds()),
		feedback.New(),
		validation.DefaultLimits(),
		ent,
		slog.New(slog.NewTextHandler(io.Discard, nil)),
	)
}

func submit(t *testing.T, s *Service) error {
	t.Helper()
	_, err := s.SubmitAttempt(context.Background(), SubmitCommand{
		UserID:             uuid.New(),
		Audio:              wav(t),
		ContentType:        "audio/wav",
		ReferenceText:      "think",
		Language:           "en-US",
		DeclaredDurationMS: 1000,
	})
	return err
}

func TestReachingTheLimitBlocksBeforeTheProviderIsCalled(t *testing.T) {
	repo := &stubRepo{used: 30}
	provider := &countingProvider{}
	resets := time.Now().Add(3 * time.Hour)

	err := submit(t, newService(repo, provider, fixedAllowance{Allowance{
		DailyLimit: 30, Since: time.Now().Add(-9 * time.Hour), ResetsAt: resets,
	}}))

	appErr := apperr.From(err)
	if appErr == nil || appErr.Code != apperr.CodeUsageLimit {
		t.Fatalf("error = %v, want USAGE_LIMIT_REACHED", err)
	}
	// The whole point: the vendor was never asked, so the blocked attempt cost nothing.
	if provider.calls != 0 {
		t.Errorf("provider called %d times on a blocked attempt, want 0", provider.calls)
	}
	if repo.saved != 0 {
		t.Errorf("blocked attempt was stored %d times, want 0", repo.saved)
	}
	// The app shows this rather than guessing a rollover hour of its own.
	if _, ok := appErr.Details["resets_at"]; !ok {
		t.Error("no resets_at in details")
	}
}

func TestBelowTheLimitPassesThrough(t *testing.T) {
	provider := &countingProvider{}
	err := submit(t, newService(&stubRepo{used: 29}, provider, fixedAllowance{Allowance{
		DailyLimit: 30, Since: time.Now().Add(-1 * time.Hour), ResetsAt: time.Now(),
	}}))
	if err != nil {
		t.Fatalf("submit: %v", err)
	}
	if provider.calls != 1 {
		t.Errorf("provider called %d times, want 1", provider.calls)
	}
}

func TestAnExemptAccountIsNeverCounted(t *testing.T) {
	// used is far past any limit; Unlimited must make that irrelevant.
	provider := &countingProvider{}
	err := submit(t, newService(&stubRepo{used: 9999}, provider,
		fixedAllowance{Allowance{Unlimited: true, DailyLimit: 30}}))
	if err != nil {
		t.Fatalf("the exempt account was blocked: %v", err)
	}
	if provider.calls != 1 {
		t.Errorf("provider called %d times, want 1", provider.calls)
	}
}

func TestNoEntitlementsMeansNoLimit(t *testing.T) {
	provider := &countingProvider{}
	if err := submit(t, newService(&stubRepo{used: 9999}, provider, nil)); err != nil {
		t.Fatalf("submit: %v", err)
	}
	if provider.calls != 1 {
		t.Errorf("provider called %d times, want 1", provider.calls)
	}
}
