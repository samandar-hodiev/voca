/// One assessed attempt, as the app shows it.
///
/// Mirrors what the backend answers with; nothing is computed here. Scoring policy lives
/// on the server so every device agrees on what 85 means.
library;

import 'feedback.dart';
import 'word_result.dart';

class PronunciationScores {
  const PronunciationScores({
    required this.accuracy,
    required this.fluency,
    required this.completeness,
    required this.overall,
  });

  final double accuracy;
  final double fluency;
  final double completeness;
  final double overall;
}

class PronunciationResult {
  const PronunciationResult({
    required this.id,
    required this.referenceText,
    required this.recognizedText,
    required this.scores,
    required this.words,
    required this.feedback,
    required this.audioDurationMs,
  });

  final String id;
  final String referenceText;
  final String recognizedText;
  final PronunciationScores scores;
  final List<WordResult> words;
  final List<PronunciationFeedback> feedback;
  final int audioDurationMs;

  /// The sounds worth practising next: the lowest-scoring phonemes, worst first.
  List<PhonemeResult> get weakestSounds {
    final all = [for (final w in words) ...w.phonemes]
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));
    return all.where((p) => p.accuracy < 60).take(3).toList();
  }
}
