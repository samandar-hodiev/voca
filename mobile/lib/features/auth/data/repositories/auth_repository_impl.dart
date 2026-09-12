/// Implements the auth contract over the API and secure storage.
library;

import 'package:dio/dio.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/session_dto.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._store);

  final AuthRemoteDataSource _remote;
  final SecureStore _store;

  // Namespaced so a future feature cannot collide with a session key.
  static const _accessKey = 'auth.access_token.v1';
  static const _refreshKey = 'auth.refresh_token.v1';
  static const _userKey = 'auth.user_id.v1';

  AuthSession? _current;

  /// The in-memory session, if the app has one.
  AuthSession? get current => _current;

  @override
  Future<AuthSession?> restoreSession() async {
    final access = await _store.read(_accessKey);
    final refresh = await _store.read(_refreshKey);
    final userId = await _store.read(_userKey);

    if (access == null || refresh == null || userId == null) return null;

    // The stored user is a placeholder: the access token is the authority, and the
    // profile is re-read from the API when a screen needs it. Storing the whole user
    // would mean a stale copy on disk.
    _current = AuthSession(
      user: AuthUser(
        id: userId,
        email: null,
        emailVerified: true,
        provider: 'email',
        isGuest: false,
      ),
      accessToken: access,
      refreshToken: refresh,
    );
    return _current;
  }

  Future<void> _persist(AuthSession session) async {
    _current = session;
    await _store.write(_accessKey, session.accessToken);
    await _store.write(_refreshKey, session.refreshToken);
    await _store.write(_userKey, session.user.id);
  }

  @override
  Future<void> signOut() async {
    final refresh = await _store.read(_refreshKey);
    if (refresh != null) {
      // Best effort: the local session is cleared whether or not the server hears about
      // it, because the person asked to be signed out.
      try {
        await _remote.logout(refresh);
      } on DioException {
        // Ignored on purpose.
      }
    }
    _current = null;
    await _store.clear();
  }

  @override
  Future<Result<void>> requestSignOutCode(String email) =>
      _guard(() => _remote.startSignOut(email.trim()));

  @override
  Future<Result<void>> confirmSignOutCode(String code) async {
    final refresh = await _store.read(_refreshKey);
    if (refresh == null) {
      return const Err(UnauthenticatedFailure(message: 'No session.'));
    }
    return _guard(() => _remote.confirmSignOut(code, refresh));
  }

  @override
  Future<Result<void>> requestAccountDeletionCode(String email) =>
      _guard(() => _remote.startAccountDeletion(email.trim()));

  @override
  Future<Result<void>> confirmAccountDeletion(String code) =>
      _guard(() => _remote.confirmAccountDeletion(code));

  /// Runs a call and turns any transport or API error into a typed failure.
  Future<Result<T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Ok(await call());
    } on DioException catch (e) {
      return Err(ErrorMapper.fromDioException(e));
    } catch (_) {
      return const Err(UnknownFailure(message: 'Something went wrong.'));
    }
  }

  @override
  Future<Result<void>> startEmailVerification(String email) =>
      _guard(() => _remote.startEmailVerification(email));

  @override
  Future<Result<void>> resendCode(String email) =>
      _guard(() => _remote.resendCode(email));

  @override
  Future<Result<void>> verifyEmail(String email, String code) =>
      _guard(() => _remote.verifyEmail(email, code));

  @override
  Future<Result<AuthSession>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    OnboardingAnswers? answers,
  }) async {
    return _guard(() async {
      final json = await _remote.register({
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        ..._answersJson(answers),
      });
      final session = SessionDto.fromJson(json).toDomain();
      await _persist(session);
      return session;
    });
  }

  @override
  Future<Result<AuthSession>> login(String email, String password) =>
      _guard(() async {
        final session = SessionDto.fromJson(
          await _remote.login(email, password),
        ).toDomain();
        await _persist(session);
        return session;
      });

  @override
  Future<Result<AuthSession>> continueAsGuest(OnboardingAnswers? answers) =>
      _guard(() async {
        final session = SessionDto.fromJson(
          await _remote.guest(_answersJson(answers)),
        ).toDomain();
        await _persist(session);
        return session;
      });

  @override
  Future<Result<AuthSession>> signInWithGoogle(
    String idToken, {
    OnboardingAnswers? answers,
  }) => _guard(() async {
    // Only the token and the preferences go up. The backend reads the name and the
    // picture from the token's signed claims, so sending them from here would be
    // both pointless and a thing to be believed that should not be.
    final session = SessionDto.fromJson(
      await _remote.google({'id_token': idToken, ..._answersJson(answers)}),
    ).toDomain();
    await _persist(session);
    return session;
  });

  @override
  Future<Result<void>> forgotPassword(String email) =>
      _guard(() => _remote.forgotPassword(email));

  @override
  Future<Result<void>> verifyPasswordCode(String email, String code) =>
      _guard(() => _remote.verifyPasswordCode(email, code));

  @override
  Future<Result<AuthSession>> resetPassword(String email, String password) =>
      _guard(() async {
        final session = SessionDto.fromJson(
          await _remote.resetPassword(email, password),
        ).toDomain();
        await _persist(session);
        return session;
      });

  @override
  Future<Result<void>> savePreferences(OnboardingAnswers answers) =>
      _guard(() => _remote.savePreferences(_answersJson(answers)));

  @override
  Future<Result<String>> uploadAvatar(String filePath) =>
      _guard(() => _remote.uploadAvatar(filePath));

  Map<String, dynamic> _answersJson(OnboardingAnswers? a) => {
    if (a?.level != null) 'cefr_level': a!.level,
    if (a?.goal != null) 'learning_goal': a!.goal,
    if (a?.dailyGoalWords != null) 'daily_goal_words': a!.dailyGoalWords,
  };

  /// The access token for the auth interceptor.
  Future<String?> accessToken() => _store.read(_accessKey);

  /// Exchanges the stored refresh token for a new pair. Returns false when the session
  /// is gone and the person must sign in again.
  Future<bool> refreshSession() async {
    final refresh = await _store.read(_refreshKey);
    if (refresh == null) return false;
    try {
      final session = SessionDto.fromJson(
        await _remote.refresh(refresh),
      ).toDomain();
      await _persist(session);
      return true;
    } on DioException {
      _current = null;
      await _store.clear();
      return false;
    }
  }
}
