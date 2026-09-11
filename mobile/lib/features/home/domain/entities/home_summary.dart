/// What the Home dashboard shows about today.
///
/// Plain data with no behaviour, so the screen can be rendered from a mock today and from
/// the backend later without either side changing shape.
library;

class HomeSummary {
  const HomeSummary({
    required this.wordsDoneToday,
    required this.dailyGoal,
    required this.streakDays,
    required this.recommended,
    required this.weakSounds,
    required this.latestScore,
    required this.scoreDelta,
  });

  final int wordsDoneToday;
  final int dailyGoal;
  final int streakDays;
  final List<PracticeSuggestion> recommended;

  /// IPA symbols, most troublesome first.
  final List<String> weakSounds;

  /// Out of 100, or null before any practice.
  final int? latestScore;

  /// Change against the previous week, in points.
  final int scoreDelta;

  double get goalProgress =>
      dailyGoal == 0 ? 0 : (wordsDoneToday / dailyGoal).clamp(0.0, 1.0);
  bool get goalMet => wordsDoneToday >= dailyGoal;
}

class PracticeSuggestion {
  const PracticeSuggestion({
    required this.word,
    required this.ipa,
    required this.focusSound,
    required this.level,
  });

  final String word;
  final String ipa;
  final String focusSound;
  final String level;
}
