/// One day of practice.
library;

class DailyProgress {
  const DailyProgress({
    required this.day,
    required this.words,
    required this.goal,
  });

  final DateTime day;
  final int words;
  final int goal;

  bool get goalMet => words >= goal;
  double get ratio => goal == 0 ? 0 : (words / goal).clamp(0.0, 1.0);
}
