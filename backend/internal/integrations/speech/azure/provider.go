// integrations/speech/azure: implements pronunciation.SpeechProvider.
//
// Orchestrates client.go then mapper.go, and returns OUR domain types. The raw Azure
// response never leaves this package.
//
// Selected at startup by SPEECH_PROVIDER=azure.
//
// See ARCHITECTURE.md 7.2, 7.3, ADR-005.

package azure
