/// The answers collected during first-launch setup.
///
/// Held in memory across the three screens and sent to the backend once, when an account
/// or a guest session is created. Collecting them before an account exists is the point:
/// asking someone to register before they have seen anything is the fastest way to lose
/// them.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/auth_session.dart';

class SetupNotifier extends Notifier<OnboardingAnswers> {
  @override
  OnboardingAnswers build() => const OnboardingAnswers();

  void setLevel(String level) => state = state.copyWith(level: level);
  void setGoal(String goal) => state = state.copyWith(goal: goal);
  void setDailyGoal(int words) => state = state.copyWith(dailyGoalWords: words);
}

final setupProvider = NotifierProvider<SetupNotifier, OnboardingAnswers>(
  SetupNotifier.new,
);

/// The levels offered, in order, as CEFR codes.
///
/// The code is the stored value; the name and description a person reads come from the
/// strings (`cefrLevelName`, `cefrLevelHint`). Not everyone knows what B1 means, so both
/// are always shown together.
const cefrLevels = <String>['A1', 'A2', 'B1', 'B2', 'C1'];

/// The learning goals offered. The identifier is stored; the name a person reads comes
/// from the strings (`learningGoalName`).
const learningGoals = <String>[
  'pronunciation',
  'confidence',
  'ielts',
  'vocabulary',
  'work',
  'everyday',
];

/// Daily practice options. Ten is recommended: enough to build a habit, small enough to
/// finish on a busy day.
const dailyGoalOptions = <int>[5, 10, 15, 20];
const recommendedDailyGoal = 10;
