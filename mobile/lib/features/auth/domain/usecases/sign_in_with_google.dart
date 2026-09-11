/// Sign in with Google.
///
/// Where each part of the flow belongs:
///
///   1. The app asks Google for the account, hands the credential to Firebase, and gets a
///      Firebase ID token. That is the [GoogleIdentityTokenProvider] port below, and the
///      only part that touches a vendor.
///   2. The token goes to the Voca backend, which verifies it against Google's published
///      certificates and answers with the normal Voca session.
///   3. The session is stored exactly as it is for an email sign-in.
///
/// Firebase is the identity provider and nothing more. The Voca backend stays the source
/// of truth for users, sessions and business rules, and a Firebase UID is never used as
/// this app's session (ADR-019, ARCHITECTURE.md 8.1).
///
/// The use case exists so no screen has to know any of that. A screen calls it and gets a
/// session or a failure.
library;

import '../../../../core/error/failure.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Obtains a Firebase ID token proving a Google sign-in.
///
/// The port is owned by the domain so the use case never imports Firebase or Google.
/// Returning null means the person closed the picker, which is not an error.
abstract interface class GoogleIdentityTokenProvider {
  /// Runs the account picker and returns a Firebase ID token, or null if cancelled.
  Future<String?> obtainIdToken();

  /// Ends the Firebase and Google sessions this provider created.
  ///
  /// Called on sign-out so the next sign-in shows the account picker again rather than
  /// silently reusing whoever was chosen last time, which on a shared phone is somebody
  /// else's account.
  Future<void> signOut();
}

class SignInWithGoogle {
  const SignInWithGoogle(this._tokens, this._repository);

  final GoogleIdentityTokenProvider _tokens;
  final AuthRepository _repository;

  /// Returns the session, or the failure to show.
  ///
  /// [answers] are the onboarding preferences collected before an account existed. They
  /// are preferences, not identity: the name and picture come from the verified token, and
  /// the backend ignores anything this app claims about who the person is.
  Future<Result<AuthSession>> call(OnboardingAnswers answers) async {
    final String? idToken;
    try {
      idToken = await _tokens.obtainIdToken();
    } catch (_) {
      // Anything the picker or Firebase throws lands here. The reason is not shown: it
      // names vendors and internal states that mean nothing to the person reading it.
      return const Err(
        ProviderFailure(message: 'Google sign-in did not complete.'),
      );
    }

    if (idToken == null) return const Err(CancelledFailure());

    return _repository.signInWithGoogle(idToken, answers: answers);
  }
}
