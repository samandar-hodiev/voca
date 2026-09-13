// integrations/speech/azure: maps the Azure response to our pronunciation domain model.
//
// Mapping rules (ARCHITECTURE.md 7.4):
//   - map every vendor field EXPLICITLY; never embed raw JSON in the domain
//   - normalize phonemes to IPA plus a display label, because vendors differ (SAPI,
//     ARPAbet, IPA) and our weak-sound data must stay comparable across providers and time
//   - unknown or absent vendor fields become explicit optionals — a provider without
//     prosody must not produce a fake prosody score
//   - vendor errors map to our apperr taxonomy, so handlers never see a vendor error type
//
// This file is covered by GOLDEN TESTS over recorded payloads in testdata/. It is the
// highest-value test suite in the backend: a vendor change would otherwise silently corrupt
// scores (ARCHITECTURE.md 22.1).

package azure

import (
	"strings"

	"github.com/samandar-hodiev/voca/backend/internal/pronunciation"
)

// errorTypes maps Azure's diagnosis onto ours.
//
// Ours is a separate vocabulary on purpose: an unrecognised value becomes ErrorNone rather
// than leaking a vendor string into the database and out to the app.
var errorTypes = map[string]pronunciation.WordErrorType{
	"None":             pronunciation.ErrorNone,
	"Mispronunciation": pronunciation.ErrorMispronunciation,
	"Omission":         pronunciation.ErrorOmission,
	"Insertion":        pronunciation.ErrorInsertion,
	"UnexpectedBreak":  pronunciation.ErrorUnexpectedBreak,
	"MissingBreak":     pronunciation.ErrorMissingBreak,
	"Monotone":         pronunciation.ErrorMonotone,
}

// toDomain converts a recognition into our provider signal.
//
// An empty AssessmentOutput means "nothing was said". The service turns that into
// NO_SPEECH_DETECTED, which is a different message from a low score and a different
// message again from a failure.
func toDomain(resp recognitionResponse) pronunciation.AssessmentOutput {
	if resp.RecognitionStatus != "Success" || len(resp.NBest) == 0 {
		return pronunciation.AssessmentOutput{Provider: providerName}
	}

	best := resp.NBest[0]

	// Silence does NOT come back as NoMatch. Recorded against the live service: a second
	// of digital silence answers Success, DisplayText ".", every score 0, and one word
	// marked Omission (testdata/assessment_silence.json). Passing that through would tell
	// somebody who never spoke that their pronunciation scored zero, which is both untrue
	// and discouraging. It is reported as nothing-heard instead.
	if silent(best) {
		return pronunciation.AssessmentOutput{Provider: providerName}
	}

	out := pronunciation.AssessmentOutput{
		Provider:       providerName,
		RecognizedText: best.Display,
		Accuracy:       best.AccuracyScore,
		Fluency:        best.FluencyScore,
		Completeness:   best.CompletenessScore,
	}

	out.Words = make([]pronunciation.WordAssessment, 0, len(best.Words))
	for _, w := range best.Words {
		errType, ok := errorTypes[w.ErrorType]
		if !ok {
			errType = pronunciation.ErrorNone
		}

		phonemes := make([]pronunciation.PhonemeAssessment, 0, len(w.Phonemes))
		for _, p := range w.Phonemes {
			// Already IPA: the request asks for it. Trimmed because the field is a label
			// and a stray space would make it a different weak sound in aggregation.
			symbol := strings.TrimSpace(p.Phoneme)
			if symbol == "" {
				continue
			}
			phonemes = append(phonemes, pronunciation.PhonemeAssessment{
				Phoneme:  symbol,
				Accuracy: p.AccuracyScore,
			})
		}

		out.Words = append(out.Words, pronunciation.WordAssessment{
			Word:     w.Word,
			Accuracy: w.AccuracyScore,
			Error:    errType,
			Phonemes: phonemes,
		})
	}

	return out
}

// silent reports whether the engine heard nothing worth assessing.
func silent(best nBestResult) bool {
	if strings.TrimSpace(strings.Trim(best.Display, ".")) != "" {
		return false
	}
	if best.AccuracyScore > 0 || best.CompletenessScore > 0 || best.PronScore > 0 {
		return false
	}
	return true
}
