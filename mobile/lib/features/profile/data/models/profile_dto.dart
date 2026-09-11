/// The shape GET /api/v1/users/me answers with.
library;

import '../../domain/entities/profile.dart';

class ProfileDto {
  const ProfileDto(this._json);

  final Map<String, dynamic> _json;

  factory ProfileDto.fromJson(Map<String, dynamic> json) => ProfileDto(json);

  /// [apiBaseUrl] resolves an avatar the backend stored as a path. A picture that came
  /// from Google is already a full URL and is left alone.
  Profile toDomain({required String apiBaseUrl}) {
    final prefs = (_json['preferences'] as Map<String, dynamic>?) ?? const {};
    return Profile(
      id: _json['id'] as String,
      provider: (_json['provider'] as String?) ?? 'email',
      isGuest: (_json['is_guest'] as bool?) ?? false,
      email: _json['email'] as String?,
      firstName: _json['first_name'] as String?,
      lastName: _json['last_name'] as String?,
      avatarUrl: _resolve(_json['avatar_url'] as String?, apiBaseUrl),
      cefrLevel: prefs['cefr_level'] as String?,
      learningGoal: prefs['learning_goal'] as String?,
      dailyGoalWords: (prefs['daily_goal_words'] as num?)?.toInt(),
    );
  }

  static String? _resolve(String? url, String base) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final trimmed = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    return url.startsWith('/') ? '$trimmed$url' : '$trimmed/$url';
  }
}
