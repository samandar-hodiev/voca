/// Attaches the access token and refreshes it once on expiry.
///
/// One place for both concerns, so no feature has to remember either
/// (ARCHITECTURE.md 8.3).
library;

import 'package:dio/dio.dart';

/// What the interceptor needs from the session, kept narrow so it does not depend on the
/// whole auth feature.
abstract interface class SessionTokens {
  Future<String?> accessToken();

  /// Exchanges the refresh token. False means the session is gone.
  Future<bool> refreshSession();
}

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(this._session, this._dio);

  final SessionTokens _session;
  final Dio _dio;

  /// Paths that must not carry a token and must never trigger a refresh: they are how a
  /// session is obtained in the first place.
  static const _publicPaths = [
    '/api/v1/auth/email/',
    '/api/v1/auth/register',
    '/api/v1/auth/login',
    '/api/v1/auth/guest',
    '/api/v1/auth/refresh',
    '/api/v1/auth/password/',
  ];

  bool _isPublic(String path) => _publicPaths.any(path.startsWith);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublic(options.path)) {
      final token = await _session.accessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;

    // Only a 401 on a protected path is worth refreshing, and only once: retrying a
    // retry would loop.
    final alreadyRetried = err.requestOptions.extra['retried'] == true;
    if (status != 401 || _isPublic(path) || alreadyRetried) {
      handler.next(err);
      return;
    }

    if (!await _session.refreshSession()) {
      handler.next(err);
      return;
    }

    try {
      // QueuedInterceptor serialises this, so a burst of parallel 401s produces one
      // refresh rather than several.
      final options = err.requestOptions..extra['retried'] = true;
      final token = await _session.accessToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
