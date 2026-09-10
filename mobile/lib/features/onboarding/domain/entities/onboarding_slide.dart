/// One onboarding slide.
///
/// Pure Dart: no Flutter, no icons, no colours. The presentation layer decides how a
/// slide looks; the domain only says what it means (ARCHITECTURE.md 4.2).
library;

class OnboardingSlide {
  const OnboardingSlide({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}
