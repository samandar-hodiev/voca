/// Startup work performed while the splash screen is visible, and the decision about
/// where to go next.
///
/// The splash covers real initialization rather than delaying the app for effect. It also
/// enforces a minimum visible duration: without one the screen would flash for a few
/// frames on a fast device, which reads as a glitch rather than as a considered opening.
///
/// This is the seam for anything that genuinely belongs at startup. Each new step is an
/// awaited call here, and nothing else changes (ARCHITECTURE.md 4.3).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../routing/routes.dart';
import '../../../onboarding/presentation/controllers/onboarding_controller.dart';

/// How long the splash stays up at minimum.
const splashMinimumDuration = Duration(milliseconds: 1400);

/// Resolves to the route the app should open once startup work is done.
///
/// The splash itself is shown on EVERY launch; only the destination changes. Onboarding
/// is a first-run experience, so once it has been completed or skipped the app goes
/// straight to the product.
final splashControllerProvider = FutureProvider<String>((ref) async {
  final started = DateTime.now();

  final hasOnboarded = await ref.watch(onboardingRepositoryProvider).hasCompleted();

  // Further startup steps go here as they arrive:
  //   await ref.read(sessionRepositoryProvider).restore();
  //   await ref.read(remoteConfigProvider.future);

  final elapsed = DateTime.now().difference(started);
  final remaining = splashMinimumDuration - elapsed;
  if (remaining > Duration.zero) {
    await Future<void>.delayed(remaining);
  }

  return hasOnboarded ? Routes.home : Routes.onboarding;
});
