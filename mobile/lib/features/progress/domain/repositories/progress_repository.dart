/// Where progress data comes from.
library;

import '../entities/progress_summary.dart';

abstract interface class ProgressRepository {
  Future<ProgressSummary> summary();
}
