// Builds the whole app for a test, with local storage faked.
//
// [onboardingCompleted] controls the branch the splash takes, which is the only piece of
// persisted state that changes routing today.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voca/app.dart';
import 'package:voca/core/config/app_config.dart';
import 'package:voca/core/config/flavor.dart';
import 'package:voca/core/di/providers.dart';
import 'package:voca/core/storage/key_value_store.dart';

/// Returns the widget to pump and the container, so a test can read providers directly.
///
/// The container outlives every route, unlike a BuildContext taken from a screen the
/// navigation under test is about to dispose.
(Widget, ProviderContainer) buildApp({
  Flavor flavor = Flavor.dev,
  bool onboardingCompleted = false,
  KeyValueStore? store,
}) {
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.forFlavor(flavor)),
      platformProvider.overrideWithValue('test'),
      keyValueStoreProvider.overrideWithValue(
        store ??
            InMemoryKeyValueStore({
              if (onboardingCompleted) 'onboarding.completed.v1': true,
            }),
      ),
    ],
  );

  return (
    UncontrolledProviderScope(container: container, child: const VocaApp()),
    container,
  );
}
