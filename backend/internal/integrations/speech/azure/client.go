// integrations/speech/azure: raw HTTP/SDK calls to Azure Speech.
//
// Owns authentication (AZURE_SPEECH_KEY, AZURE_SPEECH_REGION), the per-call timeout budget
// (about 10s), and the retry policy: AT MOST ONE retry, only for transient network or 5xx
// errors, never for a 4xx.
//
// Records provider latency, which is a first-class metric — it is our evidence of vendor
// health and the trigger for circuit breaking or switching (ARCHITECTURE.md 18.4).
//
// The key lives here and ONLY here. It never reaches the mobile app.
//
// See ARCHITECTURE.md 6.5, 7.2.

package azure
