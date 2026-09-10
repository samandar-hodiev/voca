/// Auth flow state.
///
/// Holds the address being verified across three screens, and the in-flight and failure
/// state every auth screen shares.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/error/failure.dart';
import '../../../onboarding/presentation/controllers/setup_controller.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

/// What an auth screen needs to render.
class AuthState {
  const AuthState({this.isBusy = false, this.failure, this.email});

  final bool isBusy;
  final Failure? failure;

  /// The address being verified, carried between the email, code and profile screens.
  final String? email;

  AuthState copyWith({bool? isBusy, Failure? failure, String? email, bool clearFailure = false}) =>
      AuthState(
        isBusy: isBusy ?? this.isBusy,
        failure: clearFailure ? null : (failure ?? this.failure),
        email: email ?? this.email,
      );
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  OnboardingAnswers get _answers => ref.read(setupProvider);

  void clearError() => state = state.copyWith(clearFailure: true);

  /// Runs an operation, managing the busy flag and surfacing any failure.
  ///
  /// Returns true on success, so a screen can decide whether to navigate without
  /// inspecting the state again.
  Future<bool> _run(Future<Result<dynamic>> Function() op, {String? email}) async {
    state = state.copyWith(isBusy: true, clearFailure: true, email: email);
    final result = await op();
    switch (result) {
      case Ok():
        state = state.copyWith(isBusy: false);
        return true;
      case Err(:final failure):
        state = AuthState(isBusy: false, failure: failure, email: state.email);
        return false;
    }
  }

  Future<bool> startEmailVerification(String email) =>
      _run(() => _repo.startEmailVerification(email), email: email);

  Future<bool> resendCode() =>
      _run(() => _repo.resendCode(state.email ?? ''));

  Future<bool> verifyEmail(String code) =>
      _run(() => _repo.verifyEmail(state.email ?? '', code));

  Future<bool> register({
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) =>
      _run(() => _repo.register(
            email: state.email ?? '',
            password: password,
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            answers: _answers,
          ));

  Future<bool> login(String email, String password) =>
      _run(() => _repo.login(email, password), email: email);

  Future<bool> continueAsGuest() => _run(() => _repo.continueAsGuest(_answers));

  Future<bool> forgotPassword(String email) =>
      _run(() => _repo.forgotPassword(email), email: email);

  Future<bool> verifyPasswordCode(String code) =>
      _run(() => _repo.verifyPasswordCode(state.email ?? '', code));

  Future<bool> resetPassword(String password) =>
      _run(() => _repo.resetPassword(state.email ?? '', password));
}

final authControllerProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
