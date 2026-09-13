/// Reads the day's set and the week. The only place in this feature that touches the
/// network.
library;

import 'package:dio/dio.dart';

class PracticeRemoteDataSource {
  const PracticeRemoteDataSource(this._dio);

  final Dio _dio;

  /// Asking for the current session creates today's if the learner has earned it, so the
  /// app can call this on every open without worrying about spawning sessions.
  Future<Map<String, dynamic>> currentSession() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/practice/sessions',
    );
    return res.data!['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> week() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/v1/practice/week');
    return res.data!['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> complete(String sessionId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/practice/sessions/$sessionId/complete',
    );
    return res.data!['data'] as Map<String, dynamic>;
  }
}
