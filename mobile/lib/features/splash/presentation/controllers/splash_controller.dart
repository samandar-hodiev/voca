/// Startup work performed while the splash screen is visible.
///
/// The splash exists to cover real initialization, not to delay the app for effect. Today
/// that work is small, so the controller enforces a minimum visible duration: without one
/// the screen would flash for a few frames on a fast device, which reads as a glitch
/// rather than as a considered opening.
///
/// This is the seam for work that genuinely belongs at startup — restoring a session,
/// reading preferences, fetching remote config. Each is added here as an awaited step,
/// and none of them changes anything else (ARCHITECTURE.md 4.3).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How long the splash stays up at minimum.
const splashMinimumDuration = Duration(milliseconds: 1400);

/// Completes when the app is ready to show its first real screen.
final splashControllerProvider = FutureProvider<void>((ref) async {
  final started = DateTime.now();

  // Startup steps go here as they arrive. Deliberately empty for now rather than
  // pretending to do work:
  //
  //   await ref.read(sessionRepositoryProvider).restore();
  //   await ref.read(preferencesRepositoryProvider).load();
  //   await ref.read(remoteConfigProvider.future);

  final elapsed = DateTime.now().difference(started);
  final remaining = splashMinimumDuration - elapsed;
  if (remaining > Duration.zero) {
    await Future<void>.delayed(remaining);
  }
});
