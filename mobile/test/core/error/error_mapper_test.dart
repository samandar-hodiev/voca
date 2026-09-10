// Error mapping.
//
// The mapper keys on the backend's stable error CODE, never on message text, which is why
// the API can answer in English while the app renders Uzbek (ARCHITECTURE.md 19.1).

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca/core/error/error_mapper.dart';
import 'package:voca/core/error/failure.dart';

DioException _badResponse(Map<String, dynamic> body, {int status = 400}) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: body,
    ),
  );
}

Map<String, dynamic> _envelope(String code, {Map<String, dynamic>? details}) => {
      'error': {
        'code': code,
        'message': 'Message from server',
        'request_id': 'req_123',
        if (details != null) 'details': details,
      },
    };

void main() {
  group('transport errors', () {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.connectionError,
    ]) {
      test('$type becomes a NetworkFailure', () {
        final failure = ErrorMapper.fromDioException(
          DioException(requestOptions: RequestOptions(path: '/x'), type: type),
        );
        expect(failure, isA<NetworkFailure>());
      });
    }
  });

  group('API errors', () {
    test('UNAUTHENTICATED becomes UnauthenticatedFailure', () {
      final f = ErrorMapper.fromDioException(_badResponse(_envelope('UNAUTHENTICATED')));
      expect(f, isA<UnauthenticatedFailure>());
      expect(f.requestId, 'req_123');
    });

    // These two drive different screens and must never collapse into one another
    // (ARCHITECTURE.md 19.2).
    test('PREMIUM_REQUIRED and USAGE_LIMIT_REACHED map to distinct failures', () {
      final premium = ErrorMapper.fromDioException(
        _badResponse(_envelope('PREMIUM_REQUIRED'), status: 403),
      );
      final quota = ErrorMapper.fromDioException(
        _badResponse(_envelope('USAGE_LIMIT_REACHED'), status: 429),
      );

      expect(premium, isA<PremiumRequiredFailure>());
      expect(quota, isA<UsageLimitFailure>());
      expect(premium.runtimeType, isNot(quota.runtimeType));
    });

    test('USAGE_LIMIT_REACHED reads resets_at from details', () {
      final f = ErrorMapper.fromDioException(
        _badResponse(
          _envelope('USAGE_LIMIT_REACHED', details: {'resets_at': '2026-09-11T00:00:00Z'}),
          status: 429,
        ),
      ) as UsageLimitFailure;

      expect(f.resetsAt, isNotNull);
      expect(f.resetsAt!.year, 2026);
    });

    test('provider codes become ProviderFailure', () {
      for (final code in ['PROVIDER_ERROR', 'PROVIDER_UNAVAILABLE', 'PROVIDER_TIMEOUT']) {
        expect(
          ErrorMapper.fromDioException(_badResponse(_envelope(code), status: 503)),
          isA<ProviderFailure>(),
          reason: code,
        );
      }
    });

    test('an unrecognised code stays an ApiFailure carrying the code', () {
      final f = ErrorMapper.fromDioException(
        _badResponse(_envelope('SOMETHING_NEW')),
      ) as ApiFailure;

      expect(f.code, 'SOMETHING_NEW');
    });
  });

  // A gateway or proxy answers with a body we did not produce. Saying something specific
  // about it would be a guess.
  test('a non-envelope body becomes UnknownFailure', () {
    final f = ErrorMapper.fromDioException(
      _badResponse({'unexpected': true}, status: 502),
    );
    expect(f, isA<UnknownFailure>());
  });
}
