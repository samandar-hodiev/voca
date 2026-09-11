/// Where the Home dashboard gets its data.
library;

import '../entities/home_summary.dart';

abstract interface class HomeRepository {
  /// [dailyGoal] is the person's own target from their preferences, so the dashboard
  /// never shows a goal they did not choose.
  Future<HomeSummary> summary({required int dailyGoal});
}
