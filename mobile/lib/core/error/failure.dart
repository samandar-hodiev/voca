/// Typed failures the UI switches on.
///
/// Use cases return one of these instead of throwing, so every failure state is handled
/// explicitly at the call site and no screen falls back to a generic dialog
/// (ARCHITECTURE.md 19.3).
library;

sealed class Failure {
  const Failure({required this.message, this.requestId});

  /// Text safe to show a person. Never a stack trace or an internal identifier.
  final String message;

  /// The backend request ID, when the failure came from an API call. Shown on error
  /// screens so a support report maps to a log line.
  final String? requestId;
}

/// No connectivity, DNS failure, or a timeout before the server answered.
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.requestId});
}

/// The device has a network, but the backend could not be reached: nothing is listening
/// at the configured address, a firewall dropped the connection, or the base URL points
/// somewhere else entirely.
///
/// A subtype of [NetworkFailure] so every existing `NetworkFailure()` branch still catches
/// it, and separate so a screen can say "cannot reach the server" instead of accusing the
/// person's Wi-Fi. During development this is the usual answer when the API base URL is
/// still localhost on a real phone.
class ServerUnreachableFailure extends NetworkFailure {
  const ServerUnreachableFailure({required super.message, super.requestId});
}

/// The server answered, but with an error the client should act on.
class ApiFailure extends Failure {
  const ApiFailure({
    required this.code,
    required super.message,
    super.requestId,
    this.details,
  });

  /// The stable backend error code. The UI localizes from this, never from [message].
  final String code;

  final Map<String, dynamic>? details;
}

/// The caller must sign in again.
class UnauthenticatedFailure extends Failure {
  const UnauthenticatedFailure({required super.message, super.requestId});
}

/// The action needs a subscription. Distinct from [UsageLimitFailure] on purpose: this
/// one means "not in your plan" and leads to the paywall.
class PremiumRequiredFailure extends Failure {
  const PremiumRequiredFailure({required super.message, super.requestId});
}

/// The free daily quota is spent. Means "come back tomorrow or upgrade", which is a
/// different screen from [PremiumRequiredFailure] (ARCHITECTURE.md 19.2).
class UsageLimitFailure extends Failure {
  const UsageLimitFailure({
    required super.message,
    super.requestId,
    this.resetsAt,
  });

  final DateTime? resetsAt;
}

/// An upstream provider failed or timed out. Retrying is usually worthwhile.
class ProviderFailure extends Failure {
  const ProviderFailure({required super.message, super.requestId});
}

/// The person backed out of something rather than anything going wrong.
///
/// Its own type because it is the one failure that must produce no error message at all.
/// Somebody who closes the Google account picker knows what they did, and telling them
/// "sign-in failed" would be both wrong and irritating.
class CancelledFailure extends Failure {
  const CancelledFailure() : super(message: '');
}

/// Anything not recognised. Treated as retryable but not explained in detail.
class UnknownFailure extends Failure {
  const UnknownFailure({required super.message, super.requestId});
}
