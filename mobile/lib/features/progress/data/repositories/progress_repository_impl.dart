/// Progress data from a local mock.
///
/// Stands in for the progress endpoint, which does not exist yet. The dates are computed
/// from today so the week always looks current.
library;

import '../../domain/entities/daily_progress.dart';
import '../../domain/entities/progress_summary.dart';
import '../../domain/entities/weak_sound.dart';
import '../../domain/repositories/progress_repository.dart';

class MockProgressRepository implements ProgressRepository {
  MockProgressRepository({
    DateTime Function()? now,
    this.latency = const Duration(milliseconds: 220),
  }) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Duration latency;

  @override
  Future<ProgressSummary> summary() async {
    await Future<void>.delayed(latency);
    final today = DateTime(_now().year, _now().month, _now().day);
    const words = [6, 10, 12, 4, 10, 11, 7];

    return ProgressSummary(
      overallScore: 78,
      scoreDelta: 6,
      wordsPracticed: 142,
      streakDays: 5,
      bestStreak: 9,
      week: [
        for (var i = 0; i < 7; i++)
          DailyProgress(
            day: today.subtract(Duration(days: 6 - i)),
            words: words[i],
            goal: 10,
          ),
      ],
      weakSounds: const [
        WeakSound(symbol: 'θ', example: 'think', accuracy: 54),
        WeakSound(symbol: 'r', example: 'rarely', accuracy: 61),
        WeakSound(symbol: 'w', example: 'world', accuracy: 68),
        WeakSound(symbol: 'ð', example: 'weather', accuracy: 72),
      ],
      recent: [
        PracticeRecord(
          word: 'three',
          score: 94,
          at: today.add(const Duration(hours: 9)),
        ),
        PracticeRecord(
          word: 'world',
          score: 79,
          at: today.subtract(const Duration(hours: 14)),
        ),
        PracticeRecord(
          word: 'rarely',
          score: 61,
          at: today.subtract(const Duration(hours: 30)),
        ),
        PracticeRecord(
          word: 'think',
          score: 58,
          at: today.subtract(const Duration(hours: 40)),
        ),
      ],
    );
  }
}
