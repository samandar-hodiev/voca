// pronunciation: SpeechProvider — the port for pronunciation assessment.
//
// THE CONSUMER OWNS THIS INTERFACE, not the vendor. AssessmentInput and AssessmentOutput
// are OUR types, phrased in the product's language.
//
// This signature contains NO Azure type, NO Azure enum, and NO Azure field name. If a
// vendor concept appears here, the abstraction has already failed.
//
// Implementations live in internal/integrations/speech/{azure,google,mock} and are selected
// at startup by SPEECH_PROVIDER.
//
// See ARCHITECTURE.md 7.1, ADR-006.

package pronunciation

import "context"

type SpeechProvider interface {
	// Name is the provider recorded on every attempt, so a score can always be traced to
	// the engine that produced it.
	Name() string

	AssessPronunciation(ctx context.Context, in AssessmentInput) (AssessmentOutput, error)
}
