/// The shape POST /api/v1/pronunciation/attempts answers with.
library;

import '../../domain/entities/feedback.dart';
import '../../domain/entities/pronunciation_result.dart';
import '../../domain/entities/word_result.dart';

class PronunciationResultDto {
  const PronunciationResultDto(this._json);

  final Map<String, dynamic> _json;

  factory PronunciationResultDto.fromJson(Map<String, dynamic> json) =>
      PronunciationResultDto(json);

  PronunciationResult toDomain() {
    final scores = (_json['scores'] as Map<String, dynamic>?) ?? const {};
    final words = (_json['words'] as List<dynamic>?) ?? const [];
    final feedback = (_json['feedback'] as List<dynamic>?) ?? const [];

    return PronunciationResult(
      id: (_json['id'] as String?) ?? '',
      referenceText: (_json['reference_text'] as String?) ?? '',
      recognizedText: (_json['recognized_text'] as String?) ?? '',
      audioDurationMs: (_json['audio_duration_ms'] as num?)?.toInt() ?? 0,
      scores: PronunciationScores(
        accuracy: _num(scores['accuracy']),
        fluency: _num(scores['fluency']),
        completeness: _num(scores['completeness']),
        overall: _num(scores['overall']),
      ),
      words: [
        for (final w in words.whereType<Map<String, dynamic>>())
          WordResult(
            word: (w['word'] as String?) ?? '',
            accuracy: _num(w['accuracy']),
            error: (w['error'] as String?) ?? 'none',
            phonemes: [
              for (final p
                  in ((w['phonemes'] as List<dynamic>?) ?? const [])
                      .whereType<Map<String, dynamic>>())
                PhonemeResult(
                  phoneme: (p['phoneme'] as String?) ?? '',
                  accuracy: _num(p['accuracy']),
                ),
            ],
          ),
      ],
      feedback: [
        for (final f in feedback.whereType<Map<String, dynamic>>())
          PronunciationFeedback(
            messageKey: (f['message_key'] as String?) ?? '',
            word: f['word'] as String?,
            phoneme: f['phoneme'] as String?,
            tipKey: f['tip_key'] as String?,
            priority: (f['priority'] as num?)?.toInt() ?? 100,
          ),
      ],
    );
  }

  static double _num(dynamic v) => (v as num?)?.toDouble() ?? 0;
}
