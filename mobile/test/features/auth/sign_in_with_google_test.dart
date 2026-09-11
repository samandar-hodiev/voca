import 'package:flutter_test/flutter_test.dart';
import 'package:voca/core/error/failure.dart';
import 'package:voca/features/auth/domain/entities/auth_session.dart';
import 'package:voca/features/auth/domain/repositories/auth_repository.dart';
import 'package:voca/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:voca/features/auth/domain/usecases/sign_out.dart';

class FakeTokens implements GoogleIdentityTokenProvider {
  FakeTokens({this.token, this.throws});

  final String? token;
  final Object? throws;
  int signOutCalls = 0;

  @override
  Future<String?> obtainIdToken() async {
    if (throws != null) throw throws!;
    return token;
  }

  @override
  Future<void> signOut() async => signOutCalls++;
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.result});

  final Result<AuthSession>? result;
  String? receivedToken;
  OnboardingAnswers? receivedAnswers;
  int signOutCalls = 0;

  @override
  Future<Result<AuthSession>> signInWithGoogle(
    String idToken, {
    OnboardingAnswers? answers,
  }) async {
    receivedToken = idToken;
    receivedAnswers = answers;
    return result ?? const Err(UnknownFailure(message: 'not configured'));
  }

  @override
  Future<void> signOut() async => signOutCalls++;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not used by these tests');
}

AuthSession session() => const AuthSession(
      user: AuthUser(
        id: 'u1',
        email: 'learner@example.com',
        emailVerified: true,
        provider: 'google',
        isGuest: false,
      ),
      accessToken: 'access',
      refreshToken: 'refresh',
    );

void main() {
  const answers = OnboardingAnswers(level: 'B1', goal: 'confidence', dailyGoalWords: 10);

  test('a successful sign-in forwards the token and returns the session', () async {
    final tokens = FakeTokens(token: 'firebase-id-token');
    final repo = FakeAuthRepository(result: Ok(session()));

    final result = await SignInWithGoogle(tokens, repo)(answers);

    expect(result, isA<Ok<AuthSession>>());
    expect(repo.receivedToken, 'firebase-id-token',
        reason: 'the token from the identity provider should reach the backend unchanged');
    expect(repo.receivedAnswers, answers,
        reason: 'onboarding answers are preferences and should travel with the sign-in');
  });

  // Closing the picker is not an error, and must not produce a message.
  test('cancelling produces a silent failure and never calls the backend', () async {
    final tokens = FakeTokens(token: null);
    final repo = FakeAuthRepository();

    final result = await SignInWithGoogle(tokens, repo)(answers);

    expect(result, isA<Err<AuthSession>>());
    expect((result as Err<AuthSession>).failure, isA<CancelledFailure>());
    expect(result.failure.message, isEmpty);
    expect(repo.receivedToken, isNull, reason: 'nothing should be sent when cancelled');
  });

  // Whatever Firebase or the picker throws, the person sees one calm message and never a
  // vendor's internal state.
  test('a provider error becomes a readable failure', () async {
    final tokens = FakeTokens(throws: StateError('PlatformException(sign_in_failed)'));
    final repo = FakeAuthRepository();

    final result = await SignInWithGoogle(tokens, repo)(answers);

    final failure = (result as Err<AuthSession>).failure;
    expect(failure, isA<ProviderFailure>());
    expect(failure.message, isNot(contains('PlatformException')));
    expect(failure.message, isNotEmpty);
  });

  // A token the backend refuses must surface as the backend's failure, not be swallowed.
  test('a backend refusal is passed through', () async {
    final tokens = FakeTokens(token: 'forged');
    final repo = FakeAuthRepository(
      result: const Err(ApiFailure(code: 'INVALID_CREDENTIALS', message: 'no')),
    );

    final result = await SignInWithGoogle(tokens, repo)(answers);

    final failure = (result as Err<AuthSession>).failure;
    expect(failure, isA<ApiFailure>());
    expect((failure as ApiFailure).code, 'INVALID_CREDENTIALS');
  });

  // Both sessions end, and the identity provider goes first so a hang there cannot leave
  // the person signed in locally.
  test('signing out ends the identity provider session too', () async {
    final tokens = FakeTokens();
    final repo = FakeAuthRepository();

    await SignOut(repo, tokens)();

    expect(tokens.signOutCalls, 1);
    expect(repo.signOutCalls, 1);
  });

  test('a failing identity provider does not stop the local sign-out', () async {
    final tokens = FakeTokens(throws: StateError('boom'));
    final repo = FakeAuthRepository();

    await SignOut(repo, tokens)();

    expect(repo.signOutCalls, 1,
        reason: 'somebody who asked to sign out must be signed out locally regardless');
  });
}
