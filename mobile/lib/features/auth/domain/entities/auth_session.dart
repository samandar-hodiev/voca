/// The signed-in session.
library;

class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final AuthUser user;
  final String accessToken;
  final String refreshToken;
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.emailVerified,
    required this.provider,
    required this.isGuest,
  });

  final String id;
  final String? email;
  final bool emailVerified;
  final String provider;
  final bool isGuest;
}

/// The onboarding answers, mirrored locally so the flow can collect them before an
/// account exists and send them all at once when it does.
class OnboardingAnswers {
  const OnboardingAnswers({this.level, this.goal, this.dailyGoalWords});

  /// Stable identifier: A1, A2, B1, B2 or C1. Never the label shown on screen.
  final String? level;

  /// Stable identifier: pronunciation, confidence, ielts, vocabulary, work, everyday.
  final String? goal;

  final int? dailyGoalWords;

  OnboardingAnswers copyWith({String? level, String? goal, int? dailyGoalWords}) =>
      OnboardingAnswers(
        level: level ?? this.level,
        goal: goal ?? this.goal,
        dailyGoalWords: dailyGoalWords ?? this.dailyGoalWords,
      );

  bool get isComplete => level != null && goal != null && dailyGoalWords != null;
}
