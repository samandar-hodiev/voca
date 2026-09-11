/// Loads the signed-in person's profile.
library;

import '../../../../features/auth/domain/repositories/auth_repository.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class GetProfile {
  const GetProfile(this._repository);

  final ProfileRepository _repository;

  Future<Result<Profile>> call() => _repository.me();
}
