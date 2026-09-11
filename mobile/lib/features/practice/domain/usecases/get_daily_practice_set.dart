/// Loads today's practice set.
library;

import '../entities/word.dart';
import '../repositories/practice_repository.dart';

class GetDailyPracticeSet {
  const GetDailyPracticeSet(this._repository);

  final PracticeRepository _repository;

  Future<List<Word>> call() => _repository.dailySet();
}
