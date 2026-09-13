// integrations/speech/azure: implements pronunciation.SpeechProvider.
//
// Orchestrates client.go then mapper.go, and returns OUR domain types. The raw Azure
// response never leaves this package.
//
// Selected at startup by SPEECH_PROVIDER=azure.
//
// See ARCHITECTURE.md 7.2, 7.3, ADR-005.

package azure

import (
	"context"
	"log/slog"
	"strings"

	"github.com/samandar-hodiev/voca/backend/internal/pronunciation"
)

type Provider struct {
	client *client
}

// New validates the configuration and returns a provider. A missing key or region is a
// startup error rather than a surprise on the first learner's recording.
func New(cfg Config, logger *slog.Logger) (*Provider, error) {
	c, err := newClient(cfg, logger)
	if err != nil {
		return nil, err
	}
	return &Provider{client: c}, nil
}

func (p *Provider) Name() string { return providerName }

func (p *Provider) AssessPronunciation(
	ctx context.Context, in pronunciation.AssessmentInput,
) (pronunciation.AssessmentOutput, error) {
	resp, err := p.client.assess(ctx, in)
	if err != nil {
		return pronunciation.AssessmentOutput{}, err
	}

	out := toDomain(resp)
	if len(out.Words) > 0 {
		return out, nil
	}

	// Nothing to score. That is either silence or a different word entirely, and the
	// scored response cannot tell them apart — see client.recognize. One reference-free
	// pass settles it, and what it heard becomes RecognizedText so the service can say
	// "you said X" instead of accusing a talking learner of saying nothing.
	heard, err := p.client.recognize(ctx, in)
	if err != nil {
		// The second pass is a refinement, not the assessment. Failing it must not fail
		// an attempt that already has an answer, however unhelpful that answer is.
		return out, nil
	}
	out.RecognizedText = spokenText(heard)
	return out, nil
}

// spokenText is what the engine heard, or empty when it heard nothing.
//
// Azure answers silence with "." rather than an empty string, so the punctuation it adds
// on its own has to come off before the value can be tested for emptiness.
func spokenText(resp recognitionResponse) string {
	return strings.TrimSpace(strings.Trim(strings.TrimSpace(resp.DisplayText), "."))
}
