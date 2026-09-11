/// The signed-in person as the app shows them.
///
/// Built from the backend's answer to "who am I", never from what was typed during
/// sign-up and cached locally: the server is the source of truth, and a stale copy on the
/// device is how a changed name keeps showing the old one.
library;

class Profile {
  const Profile({
    required this.id,
    required this.provider,
    required this.isGuest,
    this.email,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.cefrLevel,
    this.learningGoal,
    this.dailyGoalWords,
  });

  final String id;
  final String provider;
  final bool isGuest;
  final String? email;
  final String? firstName;
  final String? lastName;

  /// Absolute, ready to load. The backend stores its own uploads as paths, and this is
  /// resolved against the API base before it reaches a widget.
  final String? avatarUrl;

  final String? cefrLevel;
  final String? learningGoal;
  final int? dailyGoalWords;

  /// "Samandar Xodiev", or whatever part of it exists.
  String get displayName {
    final parts = [
      firstName,
      lastName,
    ].whereType<String>().where((p) => p.trim().isNotEmpty);
    return parts.join(' ');
  }

  /// Up to two letters for an avatar with no picture.
  String get initials {
    final letters = [firstName, lastName]
        .whereType<String>()
        .where((p) => p.trim().isNotEmpty)
        .map((p) => p.trim()[0].toUpperCase())
        .take(2)
        .join();
    if (letters.isNotEmpty) return letters;
    final e = email;
    return (e != null && e.isNotEmpty) ? e[0].toUpperCase() : '?';
  }
}
