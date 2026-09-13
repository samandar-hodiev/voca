/// Reads the progress dashboard. The only place in this feature that touches the network.
library;

import 'package:dio/dio.dart';

class ProgressRemoteDataSource {
  const ProgressRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> summary() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/progress/summary',
    );
    return res.data!['data'] as Map<String, dynamic>;
  }
}
