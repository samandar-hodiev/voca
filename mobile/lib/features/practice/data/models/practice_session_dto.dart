/// The shape /api/v1/practice/sessions answers with.
///
/// The day's set is a session: the same object the backend stores, items and all. The app
/// does no selection and no locking of its own — both are decided on the server, because
/// a lock a client can lift is not a lock.
library;

import '../../domain/entities/practice_session.dart';
import '../../domain/entities/word.dart';

class PracticeSessionDto {
  const PracticeSessionDto(this._json);

  final Map<String, dynamic> _json;

  factory PracticeSessionDto.fromJson(Map<String, dynamic> json) =>
      PracticeSessionDto(json);

  PracticeSession toDomain() {
    final items = (_json['items'] as List<dynamic>?) ?? const [];

    return PracticeSession(
      id: (_json['id'] as String?) ?? '',
      status: (_json['status'] as String?) ?? 'in_progress',
      itemCount: _int(_json['item_count']),
      completedItemCount: _int(_json['completed_item_count']),
      averageScore: (_json['average_score'] as num?)?.toDouble(),
      passScore: (_json['pass_score'] as num?)?.toDouble() ?? 80,
      passed: (_json['passed'] as bool?) ?? false,
      day: DateTime.tryParse('${_json['practice_day']}') ?? DateTime.now(),
      words: [
        for (final i in items.whereType<Map<String, dynamic>>()) _word(i),
      ],
    );
  }

  static Word _word(Map<String, dynamic> i) {
    final best = (i['best_score'] as num?)?.toDouble();
    return Word(
      id: (i['word_id'] as String?) ?? '',
      text: (i['text'] as String?) ?? '',
      // The server stores the transcription bare; the slashes are presentation, and this
      // is where presentation starts.
      ipa: _slashed((i['phonetic_ipa'] as String?) ?? ''),
      meaningUz: (i['meaning_uz'] as String?) ?? '',
      level: (i['cefr_level'] as String?) ?? '',
      focusSound: (i['focus_sound'] as String?) ?? '',
      status: _status(i['status'] as String?, best),
      bestScore: best?.round(),
    );
  }

  static String _slashed(String ipa) =>
      ipa.isEmpty || ipa.startsWith('/') ? ipa : '/$ipa/';

  /// The item's own status decides, with the score only breaking the tie between "tried
  /// it and it needs work" and "tried it and it was fine".
  static PronunciationStatus _status(String? status, double? best) {
    if (status == 'completed') {
      return (best ?? 0) >= 90
          ? PronunciationStatus.mastered
          : PronunciationStatus.good;
    }
    if (best == null) return PronunciationStatus.notStarted;
    return PronunciationStatus.needsWork;
  }

  static int _int(dynamic v) => (v as num?)?.round() ?? 0;
}

/// One square in the week strip.
class PracticeDayDto {
  const PracticeDayDto(this._json);

  final Map<String, dynamic> _json;

  factory PracticeDayDto.fromJson(Map<String, dynamic> json) =>
      PracticeDayDto(json);

  PracticeDay toDomain() => PracticeDay(
    day: DateTime.tryParse('${_json['day']}') ?? DateTime.now(),
    status: _dayStatus((_json['status'] as String?) ?? 'locked'),
    unlocked: (_json['unlocked'] as bool?) ?? false,
    wordCount: (_json['word_count'] as num?)?.round() ?? 0,
    completedCount: (_json['completed_count'] as num?)?.round() ?? 0,
    averageScore: (_json['average_score'] as num?)?.toDouble(),
  );

  static PracticeDayStatus _dayStatus(String raw) => switch (raw) {
    'available' => PracticeDayStatus.available,
    'in_progress' => PracticeDayStatus.inProgress,
    'passed' => PracticeDayStatus.passed,
    'failed' => PracticeDayStatus.failed,
    _ => PracticeDayStatus.locked,
  };
}
