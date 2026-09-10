/// Maps transport and API errors onto typed [Failure]s.
///
/// The mapping keys on the backend's stable error CODE, never on the message text, which
/// is why the API can return English messages while the app renders Uzbek
/// (ARCHITECTURE.md 19.1).
library;

import 'package:dio/dio.dart';

import '../network/api_response.dart';
import 'failure.dart';

abstract final class ErrorMapper {
  static Failure fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkFailure(
          message: 'The server took too long to respond.',
        );

      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return const NetworkFailure(
          message: 'No internet connection.',
        );

      case DioExceptionType.cancel:
        return const UnknownFailure(message: 'The request was cancelled.');

      case DioExceptionType.badCertificate:
        return const NetworkFailure(
          message: 'The connection is not secure.',
        );

      case DioExceptionType.badResponse:
        return _fromResponse(e.response);
    }
  }

  static Failure _fromResponse(Response<dynamic>? response) {
    final parsed = ApiErrorBody.tryParse(response?.data);

    // Not an envelope: a proxy, a gateway, or an unexpected body. Say nothing specific,
    // because we do not know anything specific.
    if (parsed == null) {
      return const UnknownFailure(message: 'Something went wrong.');
    }

    return switch (parsed.code) {
      'UNAUTHENTICATED' || 'TOKEN_EXPIRED' => UnauthenticatedFailure(
          message: parsed.message,
          requestId: parsed.requestId,
        ),
      'PREMIUM_REQUIRED' => PremiumRequiredFailure(
          message: parsed.message,
          requestId: parsed.requestId,
        ),
      'USAGE_LIMIT_REACHED' => UsageLimitFailure(
          message: parsed.message,
          requestId: parsed.requestId,
          resetsAt: _readResetsAt(parsed.details),
        ),
      'PROVIDER_ERROR' ||
      'PROVIDER_UNAVAILABLE' ||
      'PROVIDER_TIMEOUT' =>
        ProviderFailure(message: parsed.message, requestId: parsed.requestId),
      _ => ApiFailure(
          code: parsed.code,
          message: parsed.message,
          requestId: parsed.requestId,
          details: parsed.details,
        ),
    };
  }

  static DateTime? _readResetsAt(Map<String, dynamic>? details) {
    final raw = details?['resets_at'];
    return raw is String ? DateTime.tryParse(raw) : null;
  }
}
