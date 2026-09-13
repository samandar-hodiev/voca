/// Practice screen state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../data/datasources/practice_remote_data_source.dart';
import '../../data/repositories/practice_repository_impl.dart';
import '../../domain/entities/practice_session.dart';
import '../../domain/entities/word.dart';
import '../../domain/repositories/practice_repository.dart';
import '../../domain/usecases/get_daily_practice_set.dart';

/// The real day's set, decided by the server.
///
/// Tests override this with [MockPracticeRepository]: no widget test should need a server,
/// and none of them should depend on what a learner has practised.
final practiceRepositoryProvider = Provider<PracticeRepository>((ref) {
  return PracticeRepositoryImpl(
    PracticeRemoteDataSource(ref.watch(dioProvider)),
  );
});

final getDailyPracticeSetProvider = Provider<GetDailyPracticeSet>((ref) {
  return GetDailyPracticeSet(ref.watch(practiceRepositoryProvider));
});

final dailyPracticeSetProvider = FutureProvider<List<Word>>((ref) {
  return ref.watch(getDailyPracticeSetProvider)();
});

/// The level filter. Null shows every level.
final practiceLevelFilterProvider = StateProvider<String?>((ref) => null);

/// The set after the filter, derived so the screen never filters in a build method.
final filteredPracticeSetProvider = Provider<AsyncValue<List<Word>>>((ref) {
  final level = ref.watch(practiceLevelFilterProvider);
  return ref
      .watch(dailyPracticeSetProvider)
      .whenData(
        (words) => level == null
            ? words
            : words.where((w) => w.level == level).toList(),
      );
});

/// The session the learner owes: today's, or an earlier one still unpassed.
final currentSessionProvider = FutureProvider<PracticeSession>((ref) {
  return ref.watch(practiceRepositoryProvider).currentSession();
});

/// The week strip. Exactly one day is unlocked; the rest are shown so the plan is visible.
final practiceWeekProvider = FutureProvider<List<PracticeDay>>((ref) {
  return ref.watch(practiceRepositoryProvider).week();
});
