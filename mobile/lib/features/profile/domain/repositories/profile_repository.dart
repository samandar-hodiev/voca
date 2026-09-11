/// Reading the signed-in person's profile.
library;

import '../../../../features/auth/domain/repositories/auth_repository.dart';
import '../entities/profile.dart';

abstract interface class ProfileRepository {
  Future<Result<Profile>> me();
}
