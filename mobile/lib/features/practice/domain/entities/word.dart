/// A word to practise, and where the learner stands with it.
library;

/// How well a word is going. Shown with a label and an icon as well as a colour, so the
/// state never depends on colour alone.
enum PronunciationStatus { notStarted, needsWork, good, mastered }

class Word {
  const Word({
    required this.id,
    required this.text,
    required this.ipa,
    required this.meaningUz,
    required this.level,
    required this.focusSound,
    this.status = PronunciationStatus.notStarted,
    this.bestScore,
  });

  final String id;
  final String text;
  final String ipa;
  final String meaningUz;

  /// CEFR code: A1 to C1.
  final String level;

  /// The sound this word exercises, in IPA.
  final String focusSound;

  final PronunciationStatus status;

  /// Out of 100, or null if never attempted.
  final int? bestScore;
}
