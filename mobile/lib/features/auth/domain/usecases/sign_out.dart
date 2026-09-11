/// Sign out.
///
/// Two sessions have to end, not one. The Voca session is what the app runs on, and the
/// backend is told so the refresh token is revoked rather than left usable. The Google and
/// Firebase session is separate, and leaving it behind means the next Google sign-in
/// silently reuses whoever was chosen last time. On a shared phone that hands the app to
/// the wrong person, so it is ended here too (ARCHITECTURE.md 8.3).
///
/// Both halves are best effort. Somebody who asked to be signed out is signed out locally
/// whatever the network or the identity provider does.
library;

import '../repositories/auth_repository.dart';
import 'sign_in_with_google.dart';

class SignOut {
  const SignOut(this._repository, this._googleTokens);

  final AuthRepository _repository;
  final GoogleIdentityTokenProvider _googleTokens;

  Future<void> call() async {
    // The identity provider first: if it hangs or throws, the Voca session is still
    // cleared, which is the half that actually keeps somebody signed in.
    try {
      await _googleTokens.signOut();
    } catch (_) {
      // Ignored on purpose.
    }
    await _repository.signOut();
  }
}
