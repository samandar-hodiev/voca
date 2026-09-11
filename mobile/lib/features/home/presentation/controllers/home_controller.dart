/// Home dashboard state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/entities/home_summary.dart';
import '../../domain/repositories/home_repository.dart';
import '../../domain/usecases/get_home_summary.dart';

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => const MockHomeRepository(),
);

final getHomeSummaryProvider = Provider<GetHomeSummary>((ref) {
  return GetHomeSummary(ref.watch(homeRepositoryProvider));
});

/// The dashboard, sized to the person's own daily goal once the profile is known.
///
/// A profile that fails to load does not block the dashboard: it falls back to the default
/// goal rather than leaving Home empty because of an unrelated request.
final homeSummaryProvider = FutureProvider<HomeSummary>((ref) async {
  int? goal;
  try {
    goal = (await ref.watch(profileProvider.future)).dailyGoalWords;
  } catch (_) {
    // Not rethrown: a profile that failed to load must not take the dashboard down with it.
    goal = null;
  }
  return ref.watch(getHomeSummaryProvider)(dailyGoal: goal ?? 10);
});
