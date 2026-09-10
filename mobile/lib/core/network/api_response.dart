/// The API envelope.
///
/// Mirrors the backend contract (ARCHITECTURE.md 11.1):
///
///     success: {"data": ..., "meta": {"request_id": "..."}}
///     error:   {"error": {"code", "message", "details", "request_id"}}
library;

class ApiEnvelope<T> {
  const ApiEnvelope({required this.data, this.requestId});

  final T data;
  final String? requestId;

  /// Unwraps a success envelope, converting the payload with [fromJson].
  static ApiEnvelope<T> parse<T>(
    Map<String, dynamic> json,
    T Function(Object? data) fromJson,
  ) {
    final meta = json['meta'];
    return ApiEnvelope<T>(
      data: fromJson(json['data']),
      requestId: meta is Map<String, dynamic> ? meta['request_id'] as String? : null,
    );
  }
}

/// The parsed error half of the envelope.
class ApiErrorBody {
  const ApiErrorBody({
    required this.code,
    required this.message,
    this.details,
    this.requestId,
  });

  final String code;
  final String message;
  final Map<String, dynamic>? details;
  final String? requestId;

  /// Reads an error envelope. Returns null when the body is not one, which happens for
  /// gateway errors and other responses the backend did not produce.
  static ApiErrorBody? tryParse(Object? body) {
    if (body is! Map<String, dynamic>) return null;
    final error = body['error'];
    if (error is! Map<String, dynamic>) return null;

    return ApiErrorBody(
      code: error['code'] as String? ?? 'UNKNOWN',
      message: error['message'] as String? ?? 'Something went wrong.',
      details: error['details'] as Map<String, dynamic>?,
      requestId: error['request_id'] as String?,
    );
  }
}
