/// Progress dashboard state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/progress_repository_impl.dart';
import '../../domain/entities/progress_summary.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/usecases/get_progress_summary.dart';

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => MockProgressRepository(),
);

final getProgressSummaryProvider = Provider<GetProgressSummary>((ref) {
  return GetProgressSummary(ref.watch(progressRepositoryProvider));
});

final progressSummaryProvider = FutureProvider<ProgressSummary>((ref) {
  return ref.watch(getProgressSummaryProvider)();
});
