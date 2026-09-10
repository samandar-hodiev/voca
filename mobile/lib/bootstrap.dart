/// Application bootstrap, shared by every flavor.
///
/// Installs global error handling before anything can fail, builds the dependency graph,
/// and starts the app. Each `main_*.dart` supplies only its flavor.
library;

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/flavor.dart';
import 'core/di/providers.dart';
import 'core/storage/key_value_store.dart';
import 'core/storage/secure_storage.dart';

/// Starts Voca for [flavor].
///
/// Returns nothing: the guarded zone lives for the process, so there is no completion to
/// wait for. [unawaited] states that intent rather than hiding it behind a lint override.
void bootstrap(Flavor flavor) {
  // runZonedGuarded catches asynchronous errors that escape the framework's own handler.
  // Together the two cover every uncaught error in the app.
  unawaited(runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Framework errors: widget build failures, layout overflows, gesture errors.
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        _report(details.exception, details.stack, source: 'flutter');
      };

      // Errors from the platform side that never reach the framework handler.
      PlatformDispatcher.instance.onError = (error, stack) {
        _report(error, stack, source: 'platform');
        return true;
      };

      final config = AppConfig.forFlavor(flavor);

      // Opened before runApp so the first frame can read it synchronously. It is a local
      // file read and takes a few milliseconds.
      final keyValueStore = await SharedPreferencesStore.open();
      final secureStore = FlutterSecureStore.create();

      runApp(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(config),
            platformProvider.overrideWithValue(_platformName()),
            keyValueStoreProvider.overrideWithValue(keyValueStore),
            secureStoreProvider.overrideWithValue(secureStore),
          ],
          child: const VocaApp(),
        ),
      );
    },
    (error, stack) => _report(error, stack, source: 'zone'),
  ));
}

/// Records an uncaught error.
///
/// Crash reporting is not wired yet; this is the seam it plugs into. When Sentry or
/// Crashlytics arrives, it is added HERE and nowhere else, with the scrubbing rules from
/// ARCHITECTURE.md 18.4 so tokens and audio never leave the device.
void _report(Object error, StackTrace? stack, {required String source}) {
  developer.log(
    'Uncaught error ($source)',
    name: 'voca.error',
    error: error,
    stackTrace: stack,
  );
}

String _platformName() {
  if (kIsWeb) return 'web';
  if (Platform.isIOS) return 'ios';
  if (Platform.isAndroid) return 'android';
  return Platform.operatingSystem;
}
