/// Wire shapes for the auth API.
///
/// Separate from the domain entities on purpose: when the API renames a field, only the
/// mapper below changes.
library;

import '../../domain/entities/auth_session.dart';

class SessionDto {
  const SessionDto({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final UserDto user;
  final String accessToken;
  final String refreshToken;

  factory SessionDto.fromJson(Map<String, dynamic> json) => SessionDto(
        user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
      );

  AuthSession toDomain() => AuthSession(
        user: user.toDomain(),
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
}

class UserDto {
  const UserDto({
    required this.id,
    required this.email,
    required this.emailVerified,
    required this.provider,
    required this.isGuest,
  });

  final String id;
  final String? email;
  final bool emailVerified;
  final String provider;
  final bool isGuest;

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
        id: json['id'] as String,
        email: json['email'] as String?,
        // Unknown or missing values default rather than throw: the contract is
        // additive-only, so an older app must tolerate a newer server (ADR-009).
        emailVerified: json['email_verified'] as bool? ?? false,
        provider: json['provider'] as String? ?? 'email',
        isGuest: json['is_guest'] as bool? ?? false,
      );

  AuthUser toDomain() => AuthUser(
        id: id,
        email: email,
        emailVerified: emailVerified,
        provider: provider,
        isGuest: isGuest,
      );
}
