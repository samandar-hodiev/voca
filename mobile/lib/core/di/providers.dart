/// The composition root.
///
/// Riverpod is both the state layer and the dependency injection container, so each layer
/// is exposed as a provider and tests override the one they need
/// (ARCHITECTURE.md 4.3, 22.2).
///
/// Dependencies flow one way:
///
///     appConfig -> dio -> (data sources) -> (repositories) -> (use cases) -> controllers
///
/// Only the first two links exist in this foundation. The rest arrive with their features.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../network/dio_client.dart';
import '../network/interceptors/auth_interceptor.dart';
import '../storage/key_value_store.dart';
import '../../features/auth/data/datasources/firebase_google_tokens.dart';
import '../../features/auth/domain/usecases/sign_in_with_google.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/confirmed_sign_out.dart';
import '../storage/secure_storage.dart';

/// Overridden in [bootstrap] with the flavor's configuration. Reading it without an
/// override is a wiring mistake, so it throws rather than guessing.
final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('appConfigProvider must be overridden in bootstrap');
});

/// Application version reported to the backend. Overridden at bootstrap.
final appVersionProvider = Provider<String>((ref) => '0.1.0');

/// Platform name reported to the backend. Overridden at bootstrap.
final platformProvider = Provider<String>((ref) => 'unknown');

/// Non-secret local storage.
///
/// Overridden in [bootstrap] with the opened store. Reading it without an override is a
/// wiring mistake, so it throws rather than silently losing writes.
final keyValueStoreProvider = Provider<KeyValueStore>((ref) {
  throw UnimplementedError('keyValueStoreProvider must be overridden in bootstrap');
});

/// Secure storage for tokens. Overridden in [bootstrap].
final secureStoreProvider = Provider<SecureStore>((ref) {
  throw UnimplementedError('secureStoreProvider must be overridden in bootstrap');
});

/// The single HTTP client, without the auth interceptor.
///
/// The interceptor needs the repository, and the repository needs this client. The circle
/// is broken by attaching the interceptor in [authRepositoryProvider], once both exist,
/// rather than by making either one aware of the other at construction.
final dioProvider = Provider<Dio>((ref) {
  final dio = DioClient.create(
    ref.watch(appConfigProvider),
    appVersion: ref.watch(appVersionProvider),
    platform: ref.watch(platformProvider),
  );
  ref.onDispose(dio.close);
  return dio;
});

/// The session-owning repository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final repository = AuthRepositoryImpl(
    AuthRemoteDataSource(dio),
    ref.watch(secureStoreProvider),
  );

  // Attached here because only now do both halves exist.
  dio.interceptors.add(AuthInterceptor(_RepositoryTokens(repository), dio));
  return repository;
});

/// Narrows the repository to just what the interceptor needs.
class _RepositoryTokens implements SessionTokens {
  const _RepositoryTokens(this._repository);

  final AuthRepositoryImpl _repository;

  @override
  Future<String?> accessToken() => _repository.accessToken();

  @override
  Future<bool> refreshSession() => _repository.refreshSession();
}

/// Turns a Google account into a Firebase ID token.
///
/// Overridden in tests with a fake, so no test has to reach Google or Firebase.
final googleIdentityTokenProvider = Provider<GoogleIdentityTokenProvider>((ref) {
  return FirebaseGoogleTokens();
});

/// The Google sign-in flow, from account picker to a stored Voca session.
final signInWithGoogleProvider = Provider<SignInWithGoogle>((ref) {
  return SignInWithGoogle(
    ref.watch(googleIdentityTokenProvider),
    ref.watch(authRepositoryProvider),
  );
});

/// Ends both the Voca session and the identity provider's.
final signOutProvider = Provider<SignOut>((ref) {
  return SignOut(
    ref.watch(authRepositoryProvider),
    ref.watch(googleIdentityTokenProvider),
  );
});

/// The first half of a confirmed sign-out: a code to the account's own address.
final requestSignOutCodeProvider = Provider<RequestSignOutCode>((ref) {
  return RequestSignOutCode(ref.watch(authRepositoryProvider));
});

/// The second half: the code is checked on the server, then both sessions end.
final confirmSignOutProvider = Provider<ConfirmSignOut>((ref) {
  return ConfirmSignOut(
    ref.watch(authRepositoryProvider),
    ref.watch(signOutProvider),
  );
});
