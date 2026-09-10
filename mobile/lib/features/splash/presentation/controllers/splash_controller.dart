/// Startup: what work happens while the splash is visible, and where the app goes next.
///
/// The decision lives here rather than in a widget, so it can be tested without a screen
/// and changed without touching one (task requirement, startup state machine).
///
///     onboarding not done  ->  onboarding
///     onboarding done, no session  ->  auth entry
///     onboarding done, session     ->  home
///
/// The splash is shown on EVERY launch. Only the destination changes.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../routing/routes.dart';
import '../../../onboarding/presentation/controllers/onboarding_controller.dart';

/// How long the splash stays up at minimum.
///
/// Long enough to read as a considered opening rather than a flash, short enough that a
/// returning user is not held up. Initialization runs alongside it, not after it.
const splashMinimumDuration = Duration(milliseconds: 1600);

/// Resolves to the route the app should open.
final splashControllerProvider = FutureProvider<String>((ref) async {
  final started = DateTime.now();

  final onboarding = ref.watch(onboardingRepositoryProvider);
  final auth = ref.watch(authRepositoryProvider);

  // Both reads happen together rather than one after the other: neither depends on the
  // other, and the splash should not last longer than the slower of the two.
  final results = await Future.wait([
    onboarding.hasCompleted(),
    auth.restoreSession(),
  ]);

  final hasOnboarded = results[0]! as bool;
  final hasSession = results[1] != null;

  final elapsed = DateTime.now().difference(started);
  final remaining = splashMinimumDuration - elapsed;
  if (remaining > Duration.zero) {
    await Future<void>.delayed(remaining);
  }

  if (!hasOnboarded) return Routes.onboarding;
  return hasSession ? Routes.home : Routes.authEntry;
});
