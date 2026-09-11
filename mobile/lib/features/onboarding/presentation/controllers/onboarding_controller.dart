/// Onboarding state and its dependencies.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../data/repositories/onboarding_repository_impl.dart';
import '../../domain/entities/onboarding_slide.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../../../../l10n/l10n.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepositoryImpl(ref.watch(keyValueStoreProvider));
});

/// Whether onboarding has already been seen. Read by the splash to decide where to go.
final onboardingCompletedProvider = FutureProvider<bool>((ref) {
  return ref.watch(onboardingRepositoryProvider).hasCompleted();
});

/// The slides, in the current language.
///
/// Three, deliberately. Onboarding earns attention it has not been given yet, so it says
/// only what the product is, how it works, and what it asks of the person. Anything more
/// gets skipped.
List<OnboardingSlide> onboardingSlides(AppLocalizations l) => [
  OnboardingSlide(title: l.onboardingTitle1, body: l.onboardingBody1),
  OnboardingSlide(title: l.onboardingTitle2, body: l.onboardingBody2),
  OnboardingSlide(title: l.onboardingTitle3, body: l.onboardingBody3),
];
