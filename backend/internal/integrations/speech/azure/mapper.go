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
