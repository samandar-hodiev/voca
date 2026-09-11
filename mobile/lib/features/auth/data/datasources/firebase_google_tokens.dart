/// Turns a Google account into a Firebase ID token.
///
/// The ONLY file in the app that imports Firebase or Google sign-in. Everything above it
/// works with a plain token string, so replacing the identity provider means replacing
/// this class and nothing else (ARCHITECTURE.md 7.1, ADR-006, ADR-019).
///
/// The sequence, and why each step is there:
///
///   1. The Google account picker returns an account plus a Google ID token.
///   2. That credential is handed to Firebase Authentication, which is what produces a
///      token this backend knows how to verify.
///   3. Firebase returns its own ID token, which the caller forwards to the Voca backend.
///
/// A Firebase UID is never used as the app's session. The Voca backend issues the tokens
/// this app actually runs on.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/config/firebase_init.dart';
import '../../domain/usecases/sign_in_with_google.dart';

class FirebaseGoogleTokens implements GoogleIdentityTokenProvider {
  FirebaseGoogleTokens({GoogleSignIn? google, FirebaseAuth? firebase})
    : _google = google ?? GoogleSignIn(),
      _firebase = firebase;

  final GoogleSignIn _google;

  /// Resolved lazily. FirebaseAuth.instance throws when Firebase never started, and this
  /// class must be constructible on a machine that has no platform configuration yet.
  final FirebaseAuth? _firebase;

  FirebaseAuth get _auth => _firebase ?? FirebaseAuth.instance;

  @override
  Future<String?> obtainIdToken() async {
    if (!isFirebaseReady) {
      throw StateError('Firebase is not configured on this build');
    }

    final account = await _google.signIn();
    if (account == null) return null; // The picker was dismissed.

    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    final result = await _auth.signInWithCredential(credential);

    // Not cached. An ID token lives about an hour, and the one moment it is needed is
    // now, so asking for a fresh one is cheaper than reasoning about staleness.
    final token = await result.user?.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Firebase returned no ID token');
    }
    return token;
  }

  @override
  Future<void> signOut() async {
    // Both sides, in that order. Leaving the Google session behind means the next sign-in
    // silently reuses the last account instead of asking, which on a shared phone hands
    // the app to the wrong person.
    try {
      await _google.signOut();
    } catch (_) {
      // Nothing to do: the app is signing out either way.
    }
    if (isFirebaseReady) {
      try {
        await _auth.signOut();
      } catch (_) {
        // Same.
      }
    }
  }
}
