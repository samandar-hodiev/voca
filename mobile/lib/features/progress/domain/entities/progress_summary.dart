/// Everything the Progress dashboard shows.
library;

import 'daily_progress.dart';
import 'weak_sound.dart';

class ProgressSummary {
  const ProgressSummary({
    required this.overallScore,
    required this.scoreDelta,
    required this.wordsPracticed,
    required this.streakDays,
    required this.bestStreak,
    required this.week,
    required this.weakSounds,
    required this.recent,
  });

  /// Out of 100.
  final int overallScore;

  /// Change against the previous week, in points.
  final int scoreDelta;

  final int wordsPracticed;
  final int streakDays;
  final int bestStreak;

  /// Seven days, oldest first.
  final List<DailyProgress> week;

  final List<WeakSound> weakSounds;
  final List<PracticeRecord> recent;
}

class PracticeRecord {
  const PracticeRecord({
    required this.word,
    required this.score,
    required this.at,
  });

  final String word;
  final int score;
  final DateTime at;
}
