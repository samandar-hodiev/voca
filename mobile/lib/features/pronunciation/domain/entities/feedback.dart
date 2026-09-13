/// One piece of advice about an attempt.
///
/// Carries KEYS, not sentences: the wording lives in the app's ARB files, which is why a
/// third interface language was a translation task and not a backend change.
library;

class PronunciationFeedback {
  const PronunciationFeedback({
    required this.messageKey,
    this.word,
    this.phoneme,
    this.tipKey,
    this.priority = 100,
  });

  final String messageKey;
  final String? word;
  final String? phoneme;

  /// How the sound is physically made — tongue, lips, airflow. Absent when the advice is
  /// about the utterance rather than one sound.
  final String? tipKey;

  /// Lower sorts first on screen.
  final int priority;
}
