/// Turns the profile endpoint into a typed result.
library;

import 'package:dio/dio.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../features/auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';
import '../models/profile_dto.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remote, {required this.apiBaseUrl});

  final ProfileRemoteDataSource _remote;
  final String apiBaseUrl;

  @override
  Future<Result<Profile>> me() async {
    try {
      final json = await _remote.me();
      return Ok(ProfileDto.fromJson(json).toDomain(apiBaseUrl: apiBaseUrl));
    } on DioException catch (e) {
      return Err(ErrorMapper.fromDioException(e));
    } catch (_) {
      return const Err(UnknownFailure(message: 'Could not load the profile.'));
    }
  }

  @override
  Future<Result<void>> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      await _remote.updateProfile({
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
      });
      return const Ok(null);
    } on DioException catch (e) {
      return Err(ErrorMapper.fromDioException(e));
    } catch (_) {
      return const Err(UnknownFailure(message: 'Could not save the profile.'));
    }
  }
}
