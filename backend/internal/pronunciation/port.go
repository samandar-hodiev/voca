// pronunciation: SpeechProvider — the port for pronunciation assessment.
//
//   type SpeechProvider interface {
//       Name() string
//       AssessPronunciation(ctx, AssessmentInput) (AssessmentOutput, error)
//   }
//
// THE CONSUMER OWNS THIS INTERFACE, not the vendor. AssessmentInput and AssessmentOutput
// are OUR types, phrased in the product's language.
//
// This signature must contain NO Azure type, NO Azure enum, and NO Azure field name. If a
// vendor concept appears here, the abstraction has already failed.
//
// Implementations live in internal/integrations/speech/{azure,google,mock} and are selected
// at startup by SPEECH_PROVIDER.
//
// See ARCHITECTURE.md 7.1, ADR-006.

package pronunciation
