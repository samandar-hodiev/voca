/// Progress dashboard state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../data/datasources/progress_remote_data_source.dart';
import '../../data/repositories/progress_repository_impl.dart';
import '../../domain/entities/progress_summary.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/usecases/get_progress_summary.dart';

/// The real dashboard, read from the backend.
///
/// Tests override this with [MockProgressRepository]: a widget test must not need a
/// server, and none of them should depend on a learner having practised anything.
final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepositoryImpl(
    ProgressRemoteDataSource(ref.watch(dioProvider)),
  );
});

final getProgressSummaryProvider = Provider<GetProgressSummary>((ref) {
  return GetProgressSummary(ref.watch(progressRepositoryProvider));
});

final progressSummaryProvider = FutureProvider<ProgressSummary>((ref) {
  return ref.watch(getProgressSummaryProvider)();
});
