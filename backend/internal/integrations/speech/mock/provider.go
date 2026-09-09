// integrations/speech/mock: deterministic fake SpeechProvider.
//
// Used by every test and by local development, selected with SPEECH_PROVIDER=mock.
//
// This is why CI is free, deterministic, and offline, and why the ENTIRE pipeline —
// scoring, analysis, feedback, persistence, and the Flutter result screen — can be built
// and tested before Azure access exists. Implementation order deliberately builds this
// adapter BEFORE the Azure one (ARCHITECTURE.md 37, step 8).
//
// Should be able to produce: a high score, a low score with a specific weak phoneme, a
// provider timeout, and a provider error, so every UI state is reachable on demand.

package mock
