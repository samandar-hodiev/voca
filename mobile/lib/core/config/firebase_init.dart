/// One place where Firebase is started.
///
/// Firebase is the identity provider for Sign in with Google and nothing else. It turns a
/// Google credential into an ID token the app forwards to the Voca backend, which is where
/// users, sessions and every business rule live. A Firebase UID is never used as this
/// app's session (ADR-019).
///
/// Initialisation is deliberately forgiving. If Firebase cannot start, for example because
/// the platform configuration file is missing on a machine that has not been set up yet,
/// the app still runs and every other way in keeps working. Google sign-in reports itself
/// unavailable instead of crashing the launch.
library;

import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';

bool _ready = false;

/// Whether Firebase started, and therefore whether Google sign-in can work.
bool get isFirebaseReady => _ready;

/// Starts Firebase once. Safe to call more than once.
Future<void> initialiseFirebase() async {
  if (_ready) return;

  try {
    // No options are passed. Each platform reads its own configuration file, which is
    // the arrangement FlutterFire expects and keeps project identifiers out of the Dart
    // source: GoogleService-Info.plist on iOS, google-services.json on Android.
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    _ready = true;
  } catch (error, stack) {
    _ready = false;
    developer.log(
      'Firebase did not start; Google sign-in will be unavailable',
      name: 'voca.firebase',
      error: error,
      stackTrace: stack,
    );
  }
}
