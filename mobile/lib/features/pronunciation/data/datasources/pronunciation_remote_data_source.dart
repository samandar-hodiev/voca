/// Calls the assessment endpoint. The only place in this feature that touches the network.
///
/// Multipart because it carries audio. The content type is stated explicitly rather than
/// guessed from the extension: the server sniffs the bytes anyway, but a wrong declaration
/// is rejected before it gets that far.
library;

import 'package:dio/dio.dart';

class PronunciationRemoteDataSource {
  const PronunciationRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> submitAttempt({
    required String audioPath,
    required String referenceText,
    required String language,
    required int durationMs,
  }) async {
    final form = FormData.fromMap({
      'audio': await MultipartFile.fromFile(
        audioPath,
        filename: 'attempt.wav',
        contentType: DioMediaType('audio', 'wav'),
      ),
      'reference_text': referenceText,
      'language': language,
      'duration_ms': '$durationMs',
    });

    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/pronunciation/attempts',
      data: form,
    );
    return res.data!['data'] as Map<String, dynamic>;
  }
}
