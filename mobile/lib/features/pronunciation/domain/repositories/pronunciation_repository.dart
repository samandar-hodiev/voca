/// Submitting an attempt and getting it back scored.
library;

import '../../../auth/domain/repositories/auth_repository.dart';
import '../entities/pronunciation_result.dart';

abstract interface class PronunciationRepository {
  Future<Result<PronunciationResult>> submitAttempt({
    required String audioPath,
    required String referenceText,
    required String language,
    required int durationMs,
  });
}
