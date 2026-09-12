/// Reading the signed-in person's profile.
library;

import '../../../../features/auth/domain/repositories/auth_repository.dart';
import '../entities/profile.dart';

abstract interface class ProfileRepository {
  Future<Result<Profile>> me();

  /// Saves the editable half of the profile. The address is not here: changing it would
  /// change how the person signs in, which needs a flow that verifies the new one.
  Future<Result<void>> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
  });
}
