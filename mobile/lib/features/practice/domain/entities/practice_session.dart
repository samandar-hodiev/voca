/// A day of practice, and the week it sits in.
///
/// The day's set is a session rather than a list: it has a state, a score, and a verdict
/// on whether it opened the next day. All three are decided on the server.
library;

import 'word.dart';

class PracticeSession {
  const PracticeSession({
    required this.id,
    required this.status,
    required this.itemCount,
    required this.completedItemCount,
    required this.averageScore,
    required this.passScore,
    required this.passed,
    required this.day,
    required this.words,
  });

  final String id;

  /// in_progress, completed or abandoned.
  final String status;

  final int itemCount;
  final int completedItemCount;

  /// Null until the day is finished.
  final double? averageScore;

  /// The average this day has to reach to open the next one. Sent by the server so the
  /// app never carries a second copy of the number.
  final double passScore;

  final bool passed;
  final DateTime day;
  final List<Word> words;

  bool get isComplete => status == 'completed';

  /// How far through the day's words the learner is, from 0 to 1.
  double get progress =>
      itemCount == 0 ? 0 : (completedItemCount / itemCount).clamp(0.0, 1.0);
}

enum PracticeDayStatus { locked, available, inProgress, passed, failed }

class PracticeDay {
  const PracticeDay({
    required this.day,
    required this.status,
    required this.unlocked,
    required this.wordCount,
    required this.completedCount,
    required this.averageScore,
  });

  final DateTime day;
  final PracticeDayStatus status;

  /// Only ever true for one day in the week: the one the learner may practise now.
  final bool unlocked;

  final int wordCount;
  final int completedCount;
  final double? averageScore;
}
