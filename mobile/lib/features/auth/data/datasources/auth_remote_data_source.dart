/// Calls the auth endpoints.
///
/// The only place in this feature that touches the network. Nothing here interprets a
/// result; that is the repository's job.
library;

import 'package:dio/dio.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<void> startEmailVerification(String email) =>
      _dio.post<dynamic>('/api/v1/auth/email/start', data: {'email': email});

  Future<void> resendCode(String email) =>
      _dio.post<dynamic>('/api/v1/auth/email/resend', data: {'email': email});

  Future<void> verifyEmail(String email, String code) =>
      _dio.post<dynamic>('/api/v1/auth/email/verify', data: {'email': email, 'code': code});

  Future<Map<String, dynamic>> register(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>('/api/v1/auth/register', data: body);
    return res.data!['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post<Map<String, dynamic>>('/api/v1/auth/login',
        data: {'email': email, 'password': password});
    return res.data!['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> guest(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>('/api/v1/auth/guest', data: body);
    return res.data!['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> google(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>('/api/v1/auth/google', data: body);
    return res.data!['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    final res = await _dio.post<Map<String, dynamic>>('/api/v1/auth/refresh',
        data: {'refresh_token': refreshToken});
    return res.data!['data'] as Map<String, dynamic>;
  }

  Future<void> logout(String refreshToken) =>
      _dio.post<dynamic>('/api/v1/auth/logout', data: {'refresh_token': refreshToken});

  /// Sends a sign-out code to the signed-in account's own address. The server refuses
  /// an address that is not the account's.
  Future<void> startSignOut(String email) =>
      _dio.post<dynamic>('/api/v1/users/me/sign-out/start', data: {'email': email});

  /// Ends the session on the server, once the emailed code is right.
  Future<void> confirmSignOut(String code, String refreshToken) => _dio.post<dynamic>(
        '/api/v1/users/me/sign-out/confirm',
        data: {'code': code, 'refresh_token': refreshToken},
      );

  Future<void> forgotPassword(String email) =>
      _dio.post<dynamic>('/api/v1/auth/password/forgot', data: {'email': email});

  Future<void> verifyPasswordCode(String email, String code) =>
      _dio.post<dynamic>('/api/v1/auth/password/verify',
          data: {'email': email, 'code': code});

  Future<Map<String, dynamic>> resetPassword(String email, String password) async {
    final res = await _dio.post<Map<String, dynamic>>('/api/v1/auth/password/reset',
        data: {'email': email, 'password': password});
    return res.data!['data'] as Map<String, dynamic>;
  }

  Future<void> savePreferences(Map<String, dynamic> body) =>
      _dio.put<dynamic>('/api/v1/users/me/preferences', data: body);

  /// Uploads a profile picture for the signed-in person.
  ///
  /// Multipart rather than a JSON body: base64 inflates an image by a third and forces
  /// the whole thing through memory twice.
  Future<String> uploadAvatar(String filePath) async {
    final form = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(filePath),
    });
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/users/me/avatar',
      data: form,
    );
    return (res.data!['data'] as Map<String, dynamic>)['avatar_url'] as String;
  }
}