/// Route names and paths.
///
/// Typed, in one place. No screen builds a path by concatenating strings, so renaming a
/// route is a compile error rather than a broken deep link.
library;

abstract final class Routes {
  /// The first screen. A transition, not a destination: it replaces itself once startup
  /// work finishes, so it is never on the back stack.
  static const splash = '/';
  static const splashName = 'splash';

  /// First-run only. The splash sends people here once; afterwards it goes straight to
  /// [home].
  static const onboarding = '/onboarding';
  static const onboardingName = 'onboarding';

  /// First-run setup, after onboarding and before an account exists.
  static const level = '/setup/level';
  static const levelName = 'level';

  static const goal = '/setup/goal';
  static const goalName = 'goal';

  static const dailyGoal = '/setup/daily-goal';
  static const dailyGoalName = 'dailyGoal';

  /// Authentication.
  static const authEntry = '/auth';
  static const authEntryName = 'authEntry';

  static const emailSignUp = '/auth/email';
  static const emailSignUpName = 'emailSignUp';

  static const emailVerify = '/auth/email/verify';
  static const emailVerifyName = 'emailVerify';

  static const createProfile = '/auth/profile';
  static const createProfileName = 'createProfile';

  static const login = '/auth/login';
  static const loginName = 'login';

  static const forgotPassword = '/auth/forgot';
  static const forgotPasswordName = 'forgotPassword';

  static const forgotVerify = '/auth/forgot/verify';
  static const forgotVerifyName = 'forgotVerify';

  static const newPassword = '/auth/forgot/password';
  static const newPasswordName = 'newPassword';

  // Product routes. Declared so the shell can prove navigation works and so deep links
  // have stable targets. Their screens are placeholders; the real ones arrive with their
  // features (ARCHITECTURE.md 37).
  static const home = '/home';
  static const homeName = 'home';

  static const practice = '/practice';
  static const practiceName = 'practice';

  static const progress = '/progress';
  static const progressName = 'progress';

  static const profile = '/profile';
  static const profileName = 'profile';

  static const settings = '/settings';
  static const settingsName = 'settings';

  /// The design-system gallery. Development builds only; see [AppRouter].
  static const designSystem = '/_design';
  static const designSystemName = 'designSystem';
}
