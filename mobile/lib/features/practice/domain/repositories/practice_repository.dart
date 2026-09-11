/// Where practice content comes from.
library;

import '../entities/word.dart';

abstract interface class PracticeRepository {
  /// Today's recommended set, weakest sounds first.
  Future<List<Word>> dailySet();
}
