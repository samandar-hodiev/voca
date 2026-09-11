/// Calls the profile endpoint. The only place in this feature that touches the network.
library;

import 'package:dio/dio.dart';

class ProfileRemoteDataSource {
  const ProfileRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> me() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/v1/users/me');
    return res.data!['data'] as Map<String, dynamic>;
  }
}
