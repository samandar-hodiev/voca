// middleware: request body size cap.
//
// Wraps the request body in a MaxBytesReader so an oversized upload is rejected WITHOUT
// being buffered. Returns 413 AUDIO_TOO_LARGE for the upload route.
//
// First line of defence against an upload flood driving Azure cost — ARCHITECTURE.md 12.2,
// 18.3.

package middleware
