# Planned integration tests (ARCHITECTURE.md 22.2) — run on a device or emulator.
#
# Critical journey: sign in -> start practice -> play reference audio -> record -> submit ->
# see result -> retry.
#
# Also cover: microphone permission denied, offline during assessment, free quota exhausted
# (paywall appears), and premium user (no limit).
#
# Runs against the backend with SPEECH_PROVIDER=mock so results are deterministic.
