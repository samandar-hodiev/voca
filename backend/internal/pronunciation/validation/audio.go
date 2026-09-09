// pronunciation/validation: audio validation rules, applied BEFORE any provider call.
//
// Order matters — invalid input must cost us nothing:
//   1. body size cap (enforced earlier by middleware/body_limit.go)
//   2. declared MIME type against an allow-list
//   3. MAGIC-BYTE SNIFFING of actual content (a declared MIME type is a claim, not a fact)
//   4. header parse: sample rate, channel count, bit depth, duration
//   5. cross-check duration against the client-declared value
//
// Rejections return specific codes (AUDIO_TOO_LARGE, AUDIO_TOO_LONG,
// UNSUPPORTED_AUDIO_FORMAT) so the app can show an actionable message.
//
// Limits come from configuration: MAX_AUDIO_SIZE_BYTES, MAX_AUDIO_DURATION_MS.
//
// See ARCHITECTURE.md 12.1, 12.2, 18.2.

package validation
