/// Development-only request logging.
///
/// NEVER LOGS: the Authorization header, request bodies for authentication endpoints,
/// audio payloads, or any token. That list is a hard rule (ARCHITECTURE.md 18.4).
///
/// Disabled entirely in production builds.
library;

import 'dart:developer' as developer;

import 'package:dio/dio.dart';

class LoggingInterceptor extends Interceptor {
  const LoggingInterceptor({this.enabled = false});

  final bool enabled;

  static const _redactedHeaders = {'authorization', 'cookie', 'x-hub-signature-256'};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enabled) {
      developer.log(
        '-> ${options.method} ${options.uri}',
        name: 'voca.http',
      );
      final safeHeaders = Map<String, dynamic>.from(options.headers)
        ..removeWhere((k, _) => _redactedHeaders.contains(k.toLowerCase()));
      developer.log('   headers: $safeHeaders', name: 'voca.http');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (enabled) {
      developer.log(
        '<- ${response.statusCode} ${response.requestOptions.uri}',
        name: 'voca.http',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enabled) {
      developer.log(
        '<- ERROR ${err.response?.statusCode} ${err.requestOptions.uri} (${err.type})',
        name: 'voca.http',
      );
    }
    handler.next(err);
  }
}
