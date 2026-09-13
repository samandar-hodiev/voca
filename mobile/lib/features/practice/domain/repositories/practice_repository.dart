/// Where practice content comes from.
library;

import '../entities/practice_session.dart';
import '../entities/word.dart';

abstract interface class PracticeRepository {
  /// Today's recommended set, weakest sounds first.
  Future<List<Word>> dailySet();

  /// The set the learner owes: today's, or an earlier one they have not yet passed.
  /// Asking for it creates today's when they have earned it.
  Future<PracticeSession> currentSession();

  /// The week ahead. Exactly one day is unlocked; the rest are shown so the plan is
  /// visible, not so it can be skipped.
  Future<List<PracticeDay>> week();

  /// Closes the day and returns the verdict, including whether the next day opened.
  Future<PracticeSession> complete(String sessionId);
}
