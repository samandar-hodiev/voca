/// Turns the assessment endpoint into a typed result.
library;

import 'package:dio/dio.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/pronunciation_result.dart';
import '../../domain/repositories/pronunciation_repository.dart';
import '../datasources/pronunciation_remote_data_source.dart';
import '../models/pronunciation_result_dto.dart';

class PronunciationRepositoryImpl implements PronunciationRepository {
  const PronunciationRepositoryImpl(this._remote);

  final PronunciationRemoteDataSource _remote;

  @override
  Future<Result<PronunciationResult>> submitAttempt({
    required String audioPath,
    required String referenceText,
    required String language,
    required int durationMs,
  }) async {
    try {
      final json = await _remote.submitAttempt(
        audioPath: audioPath,
        referenceText: referenceText,
        language: language,
        durationMs: durationMs,
      );
      return Ok(PronunciationResultDto.fromJson(json).toDomain());
    } on DioException catch (e) {
      return Err(ErrorMapper.fromDioException(e));
    } catch (_) {
      return const Err(
        UnknownFailure(message: 'Could not assess the recording.'),
      );
    }
  }
}
