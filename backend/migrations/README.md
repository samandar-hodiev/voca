# Versioned SQL migrations (golang-migrate format: NNNNNN_name.up.sql / .down.sql).
#
# Planned initial set, following ARCHITECTURE.md 10:
#   000001_init            users, profiles, user_preferences
#   000002_content         categories, words (incl. target_phonemes, accent, cefr_level)
#   000003_practice        practice_sessions, practice_items
#   000004_pronunciation   pronunciation_attempts, phoneme_results, feedback
#   000005_progress        daily_progress, streaks
#   000006_subscription    subscriptions, subscription_events
#   000007_devices         devices
#
# Rules:
#   - migrations must be FORWARD-COMPATIBLE so old and new instances can run side by side
#     during a rolling deploy (ARCHITECTURE.md 24.4)
#   - enums are text columns with CHECK constraints, not native PostgreSQL enum types,
#     because we WILL add practice types and statuses and a check constraint is trivial to
#     extend while a native enum is a locking migration (ARCHITECTURE.md 10)
#   - every migration has a tested down step
#   - CI runs migrations against a scratch database so a broken migration never reaches
#     staging
