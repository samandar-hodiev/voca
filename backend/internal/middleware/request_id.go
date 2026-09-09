// middleware: request ID.
//
// Accepts X-Request-ID from the client or generates one, stores it in context.Context,
// attaches it to every log line, and echoes it in the response header.
//
// The app shows this ID in its error state, so a user's screenshot is directly traceable to
// a log line. The same value propagates into provider calls as the correlation ID, which is
// the seam that later makes distributed tracing an addition rather than a retrofit.
//
// See ARCHITECTURE.md 18.4.

package middleware
