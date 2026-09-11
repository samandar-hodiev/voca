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

  /// Signs in with a Google identity token. The token is verified SERVER-SIDE; the app
  /// only forwards what Google gave it.
  Future<Result<AuthSession>> signInWithGoogle(
    String idToken, {
    String firstName,
    String lastName,
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
}
