// pkg/logger: log/slog setup (JSON handler, level from LOG_LEVEL).
//
// pkg/ holds GENERIC helpers with no product knowledge — the only things that would still
// make sense lifted into another repository. If something here needs a domain type, it
// belongs in internal/ instead.
//
// See ARCHITECTURE.md 28 (internal vs pkg), 18.4.

package logger
