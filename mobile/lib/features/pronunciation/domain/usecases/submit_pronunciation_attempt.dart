/// Sends one recording for assessment.
library;

import '../../../auth/domain/repositories/auth_repository.dart';
import '../entities/pronunciation_result.dart';
import '../repositories/pronunciation_repository.dart';

class SubmitPronunciationAttempt {
  const SubmitPronunciationAttempt(this._repository);

  final PronunciationRepository _repository;

  Future<Result<PronunciationResult>> call({
    required String audioPath,
    required String referenceText,
    required String language,
    required int durationMs,
  }) => _repository.submitAttempt(
    audioPath: audioPath,
    referenceText: referenceText,
    language: language,
    durationMs: durationMs,
  );
}
