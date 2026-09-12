/// Saves the editable half of the signed-in person's profile.
library;

import '../../../auth/domain/repositories/auth_repository.dart';
import '../repositories/profile_repository.dart';

class UpdateProfile {
  const UpdateProfile(this._repository);

  final ProfileRepository _repository;

  Future<Result<void>> call({
    required String firstName,
    required String lastName,
    required String phone,
  }) => _repository.updateProfile(
    firstName: firstName,
    lastName: lastName,
    phone: phone,
  );
}
