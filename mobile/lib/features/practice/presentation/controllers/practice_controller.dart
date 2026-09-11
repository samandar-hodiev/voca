/// Practice screen state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/practice_repository_impl.dart';
import '../../domain/entities/word.dart';
import '../../domain/repositories/practice_repository.dart';
import '../../domain/usecases/get_daily_practice_set.dart';

final practiceRepositoryProvider = Provider<PracticeRepository>(
  (ref) => const MockPracticeRepository(),
);

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
