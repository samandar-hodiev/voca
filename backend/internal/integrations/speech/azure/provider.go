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
	return toDomain(resp), nil
}
