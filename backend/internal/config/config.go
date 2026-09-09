// config: typed application configuration, loaded from environment variables only.
//
// Twelve-factor: no config files with secrets in the repository. FAIL FAST at startup on
// anything missing or malformed — a service that boots with a missing Azure key and only
// discovers it on the first user request is worse than one that refuses to start.
//
// Groups: app (APP_ENV, PORT, LOG_LEVEL), database, JWT, speech provider, payment provider,
// analytics, notifications, cache, business limits (FREE_DAILY_ASSESSMENT_LIMIT, audio
// caps), scoring weights, observability.
//
// The full variable list with formats is ARCHITECTURE.md 25.2 and backend/.env.example.

package config
