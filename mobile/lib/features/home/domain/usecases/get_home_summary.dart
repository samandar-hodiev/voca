/// Loads the Home dashboard.
library;

import '../entities/home_summary.dart';
import '../repositories/home_repository.dart';

class GetHomeSummary {
  const GetHomeSummary(this._repository);

  final HomeRepository _repository;

  Future<HomeSummary> call({required int dailyGoal}) =>
      _repository.summary(dailyGoal: dailyGoal);
}
