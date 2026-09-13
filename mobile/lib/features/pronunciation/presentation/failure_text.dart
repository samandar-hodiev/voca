/// Why an attempt did not produce a score, in the reader's language.
///
/// Maps the backend's stable error CODE, never its message text, the same way
/// authFailureMessage does — the API answers in English while the app may be speaking
/// Uzbek or Russian.
library;

import '../../../core/audio/audio_recorder.dart';
import '../../../core/error/failure.dart';
import '../../../l10n/l10n.dart';

String assessmentFailureMessage(AppLocalizations l, Failure failure) {
  if (failure is ApiFailure) {
    return switch (failure.code) {
      'AUDIO_TOO_SHORT' => l.recordingTooShort,
      // Both mean the same thing to a learner: you talked for too long. The distinction
      // between duration and bytes is ours, not theirs.
      'AUDIO_TOO_LONG' ||
      'AUDIO_TOO_LARGE' ||
      'PAYLOAD_TOO_LARGE' => l.errorAudioTooLong,
      'UNSUPPORTED_AUDIO_FORMAT' => l.errorAudioFormat,
      'NO_SPEECH_DETECTED' => l.errorNoSpeech,
      // The learner spoke, just not the word they were asked for. Naming what was heard
      // is the whole point: "wrong word" alone leaves them guessing which part missed.
      'WRONG_WORD_SPOKEN' => switch (failure.details?['heard']) {
        final String heard when heard.trim().isNotEmpty => l.errorWrongWord(
          heard,
        ),
        _ => l.errorWrongWordUnknown,
      },
      'PROVIDER_TIMEOUT' ||
      'PROVIDER_UNAVAILABLE' ||
      'PROVIDER_ERROR' => l.errorAssessmentUnavailable,
      'USAGE_LIMIT_REACHED' => l.errorUsageLimit,
      'TOO_MANY_REQUESTS' || 'RATE_LIMITED' => l.errorTooManyRequests,
      _ => l.errorGeneric,
    };
  }
  return switch (failure) {
    UnauthenticatedFailure() => l.errorSessionExpired,
    // Before NetworkFailure: it is a subtype, so the wider branch would swallow it.
    ServerUnreachableFailure() => l.errorServerUnreachable,
    NetworkFailure() => l.errorNoInternet,
    UsageLimitFailure() => l.errorUsageLimit,
    ProviderFailure() => l.errorAssessmentUnavailable,
    _ => l.errorGeneric,
  };
}

/// Why the recording itself failed, before anything was sent.
String recordingProblemMessage(AppLocalizations l, RecordingProblem problem) =>
    switch (problem) {
      RecordingProblem.permissionDenied => l.micPermissionDenied,
      RecordingProblem.tooShort => l.recordingTooShort,
      RecordingProblem.failed => l.recordingFailed,
    };
