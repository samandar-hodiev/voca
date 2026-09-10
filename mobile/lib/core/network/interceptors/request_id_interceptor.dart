/// Attaches client identification headers and retains the backend request ID.
///
/// The backend echoes `X-Request-ID`; keeping it lets an error screen show the identifier
/// that maps straight to a server log line (ARCHITECTURE.md 18.4).
library;

import 'package:dio/dio.dart';

class RequestIdInterceptor extends Interceptor {
  RequestIdInterceptor({required this.appVersion, required this.platform});

  final String appVersion;
  final String platform;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-App-Version'] = appVersion;
    options.headers['X-Platform'] = platform;
    handler.next(options);
  }
}
