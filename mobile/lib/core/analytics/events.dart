// core/analytics: the typed event catalogue — a sealed AnalyticsEvent hierarchy.
//
// TYPED, NOT STRINGLY-TYPED, so an event name or property cannot be misspelled in one place
// and silently break a funnel.
//
// Client events (ARCHITECTURE.md 16.3): app_opened, onboarding_started, onboarding_completed,
// signup_completed, login_completed, practice_started, word_viewed, audio_played,
// recording_started, recording_completed, assessment_requested, retry_clicked,
// session_completed, weak_sound_viewed, premium_viewed, paywall_dismissed.
//
// Money and truth events (subscription_started, trial_started, assessment_completed) are
// emitted by the BACKEND, because a client can be tampered with.
//
// Never attach raw audio, email addresses, tokens, or free-text input (ARCHITECTURE.md 16.5).
// Keep in step with backend/internal/analytics/events.go and docs/product/events.md.
