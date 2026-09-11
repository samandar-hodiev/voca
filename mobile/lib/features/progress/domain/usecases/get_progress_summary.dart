/// Loads the Progress dashboard.
library;

import '../entities/progress_summary.dart';
import '../repositories/progress_repository.dart';

class GetProgressSummary {
  const GetProgressSummary(this._repository);

  final ProgressRepository _repository;

  Future<ProgressSummary> call() => _repository.summary();
}
