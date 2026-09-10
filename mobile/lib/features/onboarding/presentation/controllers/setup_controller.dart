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

final setupProvider =
    NotifierProvider<SetupNotifier, OnboardingAnswers>(SetupNotifier.new);

/// The levels offered, in order.
///
/// The CEFR code is the stored value; the label is what a person reads. Not everyone
/// knows what B1 means, so both are always shown together.
const cefrLevels = <({String code, String label, String description})>[
  (code: 'A1', label: 'Boshlang‘ich', description: 'Oddiy so‘z va iboralar'),
  (code: 'A2', label: 'Elementar', description: 'Kundalik oddiy suhbat'),
  (code: 'B1', label: 'O‘rta', description: 'Tanish mavzularda erkin gaplashaman'),
  (code: 'B2', label: 'O‘rtadan yuqori', description: 'Murakkab matnlarni tushunaman'),
  (code: 'C1', label: 'Yuqori', description: 'Deyarli erkin so‘zlashaman'),
];

/// The learning goals offered. The identifier is stored, the label is shown.
const learningGoals = <({String id, String label})>[
  (id: 'pronunciation', label: 'Talaffuzimni yaxshilash'),
  (id: 'confidence', label: 'Ishonchli gapirish'),
  (id: 'ielts', label: 'IELTS ga tayyorgarlik'),
  (id: 'vocabulary', label: 'So‘z boyligini oshirish'),
  (id: 'work', label: 'Ish uchun ingliz tili'),
  (id: 'everyday', label: 'Kundalik muloqot'),
];

/// Daily practice options. Ten is recommended: enough to build a habit, small enough to
/// finish on a busy day.
const dailyGoalOptions = <int>[5, 10, 15, 20];
const recommendedDailyGoal = 10;
