/// The single HTTP client.
///
/// One Dio instance for the whole app. Interceptors give one place for headers, logging,
/// and later authentication and refresh, which is why no feature may construct its own
/// client or reach for a second networking library (ARCHITECTURE.md 4.5, 17).
///
/// The app talks ONLY to the Voca backend. It never calls Azure, an AI provider, or a
/// database directly (ARCHITECTURE.md 31.4).
library;

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../config/flavor.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/request_id_interceptor.dart';

abstract final class DioClient {
  static Dio create(
    AppConfig config, {
    required String appVersion,
    required String platform,
    SessionTokens? session,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        // Assessment is the slowest call in the product and is bounded server-side at
        // about 10 seconds, so the client budget sits comfortably above it.
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {'Accept': 'application/json'},
        // Non-2xx is handled by the error mapper rather than by throwing on some codes
        // and not others.
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    dio.interceptors.addAll([
      RequestIdInterceptor(appVersion: appVersion, platform: platform),
      // Logging runs BEFORE the auth interceptor so it never sees an Authorization
      // header, and it redacts one anyway.
      LoggingInterceptor(enabled: config.flavor.isDebugFriendly),
      if (session != null) AuthInterceptor(session, dio),
    ]);

    return dio;
  }
}
