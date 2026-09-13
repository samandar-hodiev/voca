/// The shape GET /api/v1/progress/summary answers with.
///
/// Every number here is derived on the server from the learner's own attempts. The app
/// does no arithmetic of its own: two places computing a streak is two places to disagree.
library;

import '../../domain/entities/daily_progress.dart';
import '../../domain/entities/progress_summary.dart';
import '../../domain/entities/weak_sound.dart';

class ProgressSummaryDto {
  const ProgressSummaryDto(this._json);

  final Map<String, dynamic> _json;

  factory ProgressSummaryDto.fromJson(Map<String, dynamic> json) =>
      ProgressSummaryDto(json);

  ProgressSummary toDomain() {
    final week = (_json['week'] as List<dynamic>?) ?? const [];
    final weak = (_json['weak_sounds'] as List<dynamic>?) ?? const [];
    final recent = (_json['recent'] as List<dynamic>?) ?? const [];

    return ProgressSummary(
      overallScore: _int(_json['overall_score']),
      scoreDelta: _int(_json['score_delta']),
      wordsPracticed: _int(_json['words_practiced']),
      streakDays: _int(_json['streak_days']),
      bestStreak: _int(_json['best_streak']),
      week: [
        for (final d in week.whereType<Map<String, dynamic>>())
          DailyProgress(
            // A plain date, because which day it is was already decided in the learner's
            // own timezone. Parsing it as local midnight keeps it that day.
            day: DateTime.tryParse('${d['day']}') ?? DateTime.now(),
            words: _int(d['words']),
            goal: _int(d['goal']),
          ),
      ],
      weakSounds: [
        for (final w in weak.whereType<Map<String, dynamic>>())
          WeakSound(
            symbol: (w['phoneme'] as String?) ?? '',
            example: (w['example'] as String?) ?? '',
            accuracy: _int(w['accuracy']),
          ),
      ],
      recent: [
        for (final r in recent.whereType<Map<String, dynamic>>())
          PracticeRecord(
            word: (r['word'] as String?) ?? '',
            score: _int(r['score']),
            at: DateTime.tryParse('${r['at']}')?.toLocal() ?? DateTime.now(),
          ),
      ],
    );
  }

  static int _int(dynamic v) => (v as num?)?.round() ?? 0;
}
