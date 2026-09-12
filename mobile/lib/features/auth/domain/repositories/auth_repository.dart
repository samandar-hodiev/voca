/// The auth contract the UI depends on.
///
/// Every method returns a typed [Failure] on the error path rather than throwing, so a
/// screen handles each case explicitly (ARCHITECTURE.md 19.3).
library;

import '../../../../core/error/failure.dart';
import '../entities/auth_session.dart';

/// A result that is either a value or a failure.
sealed class Result<T> {
  const Result();
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

abstract interface class AuthRepository {
  /// The session restored at startup, or null when nobody is signed in.
  Future<AuthSession?> restoreSession();

  Future<Result<void>> startEmailVerification(String email);
  Future<Result<void>> resendCode(String email);
  Future<Result<void>> verifyEmail(String email, String code);

  Future<Result<AuthSession>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    OnboardingAnswers? answers,
  });

  Future<Result<AuthSession>> login(String email, String password);
  Future<Result<AuthSession>> continueAsGuest(OnboardingAnswers? answers);

  /// Signs in with a Firebase ID token proving a Google sign-in.
  ///
  /// The token is verified SERVER-SIDE and the app only forwards it. No name is sent: the
  /// backend takes the identity from the token's signed claims and ignores anything this
  /// app claims about who the person is. Only [answers], which are preferences rather than
  /// identity, travel with it.
  Future<Result<AuthSession>> signInWithGoogle(
    String idToken, {
    OnboardingAnswers? answers,
  });

  Future<Result<void>> forgotPassword(String email);
  Future<Result<void>> verifyPasswordCode(String email, String code);
  Future<Result<AuthSession>> resetPassword(String email, String password);

  Future<Result<void>> savePreferences(OnboardingAnswers answers);

  /// Uploads a profile picture and returns the URL it was stored at.
  ///
  /// Requires a session, so it runs after registration rather than as part of it.
  Future<Result<String>> uploadAvatar(String filePath);

  Future<void> signOut();

  /// Asks for a sign-out code at [email], which must be the account's own address.
  Future<Result<void>> requestSignOutCode(String email);

  /// Checks the emailed code. The server ends the session only if it is right. Local
  /// storage is not touched here; [signOut] clears it once this succeeds.
  Future<Result<void>> confirmSignOutCode(String code);

  /// Asks for an account-deletion code at [email], which must be the account's own
  /// address. Kept apart from [requestSignOutCode] so neither code can stand in for the
  /// other: one ends a session, the other destroys the account.
  Future<Result<void>> requestAccountDeletionCode(String email);

  /// Deletes the account on the server if the emailed code is right. Local storage is not
  /// touched here; [signOut] clears it once this succeeds.
  Future<Result<void>> confirmAccountDeletion(String code);
}
