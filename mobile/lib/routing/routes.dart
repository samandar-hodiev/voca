/// Route names and paths.
///
/// Typed, in one place. No screen builds a path by concatenating strings, so renaming a
/// route is a compile error rather than a broken deep link.
library;

abstract final class Routes {
  static const shell = '/';
  static const shellName = 'shell';

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
