// integrations/speech/mock: deterministic fake SpeechProvider.
//
// Used by every test and by local development, selected with SPEECH_PROVIDER=mock.
//
// This is why CI is free, deterministic, and offline, and why the ENTIRE pipeline —
// scoring, analysis, feedback, persistence, and the Flutter result screen — can be built
// and tested before Azure access exists. Implementation order deliberately builds this
// adapter BEFORE the Azure one (ARCHITECTURE.md 37, step 8).
//
// Deterministic on purpose: the same reference text always produces the same result, so a
// test can assert an exact score and a developer sees the same screen twice. The outcome
// is chosen by a marker in the reference text, which is how every UI state — including the
// failures — is reachable on demand without editing code:
//
//	"[low]"     a poor score with a specific weak phoneme
//	"[timeout]" the provider timing out
//	"[error]"   the provider failing
//	anything else, a high score
package mock

import (
	"context"
	"errors"
	"strings"

	"github.com/samandar-hodiev/voca/backend/internal/pronunciation"
)

// ErrProviderFailed is what the caller sees for the "[error]" marker. The service maps it
// onto a provider failure the same way it would map a real one.
var ErrProviderFailed = errors.New("mock speech provider: simulated failure")

// ErrTimeout stands in for a provider that did not answer in time.
var ErrTimeout = errors.New("mock speech provider: simulated timeout")

type Provider struct{}

func New() *Provider { return &Provider{} }

func (p *Provider) Name() string { return "mock" }

func (p *Provider) AssessPronunciation(
	ctx context.Context, in pronunciation.AssessmentInput,
) (pronunciation.AssessmentOutput, error) {
	// Honour cancellation the way a real HTTP call would, so timeout handling upstream is
	// exercised against the fake too.
	if err := ctx.Err(); err != nil {
		return pronunciation.AssessmentOutput{}, err
	}

	text := strings.ToLower(in.ReferenceText)
	switch {
	case strings.Contains(text, "[timeout]"):
		return pronunciation.AssessmentOutput{}, ErrTimeout
	case strings.Contains(text, "[error]"):
		return pronunciation.AssessmentOutput{}, ErrProviderFailed
	case strings.Contains(text, "[low]"):
		return p.lowScore(in), nil
	default:
		return p.highScore(in), nil
	}
}

// highScore is what a good attempt looks like: every word clean.
func (p *Provider) highScore(in pronunciation.AssessmentInput) pronunciation.AssessmentOutput {
	words := splitWords(in.ReferenceText)
	out := pronunciation.AssessmentOutput{
		Provider:       p.Name(),
		RecognizedText: in.ReferenceText,
		Accuracy:       96,
		Fluency:        94,
		Completeness:   100,
	}
	for _, w := range words {
		out.Words = append(out.Words, pronunciation.WordAssessment{
			Word:     w,
			Accuracy: 96,
			Error:    pronunciation.ErrorNone,
			Phonemes: phonemesFor(w, 96),
		})
	}
	return out
}

// lowScore is what a struggling attempt looks like: the first word mispronounced, with its
// first phoneme clearly the culprit, so the weak-sound path has something real to find.
func (p *Provider) lowScore(in pronunciation.AssessmentInput) pronunciation.AssessmentOutput {
	words := splitWords(strings.ReplaceAll(in.ReferenceText, "[low]", ""))
	out := pronunciation.AssessmentOutput{
		Provider:       p.Name(),
		RecognizedText: strings.Join(words, " "),
		Accuracy:       48,
		Fluency:        62,
		Completeness:   90,
	}
	for i, w := range words {
		accuracy, errType := 88.0, pronunciation.ErrorNone
		if i == 0 {
			accuracy, errType = 32, pronunciation.ErrorMispronunciation
		}
		out.Words = append(out.Words, pronunciation.WordAssessment{
			Word:     w,
			Accuracy: accuracy,
			Error:    errType,
			Phonemes: phonemesFor(w, accuracy),
		})
	}
	return out
}

func splitWords(text string) []string {
	fields := strings.Fields(strings.TrimSpace(text))
	cleaned := make([]string, 0, len(fields))
	for _, f := range fields {
		w := strings.Trim(strings.ToLower(f), ".,!?;:\"'")
		if w != "" {
			cleaned = append(cleaned, w)
		}
	}
	return cleaned
}

// phonemesFor stands in for a phoneme breakdown by using the word's letters. It is not
// phonetics and does not pretend to be; it exists so the result screen has per-phoneme
// rows to render and the weak-sound aggregation has rows to count.
func phonemesFor(word string, wordAccuracy float64) []pronunciation.PhonemeAssessment {
	out := make([]pronunciation.PhonemeAssessment, 0, len(word))
	for i, r := range word {
		accuracy := wordAccuracy
		// The first sound carries the failure, which is what makes "[low]" produce a
		// weak sound a test can name.
		if i == 0 && wordAccuracy < 60 {
			accuracy = 18
		}
		out = append(out, pronunciation.PhonemeAssessment{
			Phoneme:  string(r),
			Accuracy: accuracy,
		})
	}
	return out
}
