/// Deleting the account, confirmed from its own mailbox.
///
/// The same shape as the confirmed sign-out next to it, guarding something that cannot be
/// undone. The address check and the code check both happen on the server, the account is
/// deleted and every session revoked there, and only then is anything cleared here.
///
/// A guest has no mailbox and never reaches this: there is no identity to prove, and
/// signing out already leaves nothing behind.
library;

import '../repositories/auth_repository.dart';
import 'sign_out.dart';

class RequestAccountDeletionCode {
  const RequestAccountDeletionCode(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call(String email) =>
      _repository.requestAccountDeletionCode(email);
}

class DeleteAccount {
  const DeleteAccount(this._repository, this._signOut);

  final AuthRepository _repository;
  final SignOut _signOut;

  /// Deletes the account if [code] is right. On any failure nothing is deleted and the
  /// session is left alone.
  ///
  /// [SignOut] runs afterwards rather than a bare storage wipe, so the Google session ends
  /// too. Leaving it behind would let the next Google sign-in silently walk back into an
  /// account that no longer exists.
  Future<Result<void>> call(String code) async {
    final result = await _repository.confirmAccountDeletion(code);
    if (result is Ok<void>) await _signOut();
    return result;
  }
}
