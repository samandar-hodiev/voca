/// Signing out, confirmed from the account's own mailbox.
///
/// A person with an address types it, is sent a code there, and is signed out only once
/// the server accepts that code. The address check and the code check both happen on the
/// server, and the session is revoked there before anything is cleared here. A guest has
/// no mailbox and is signed out after a plain confirmation instead, through [SignOut].
library;

import '../repositories/auth_repository.dart';
import 'sign_out.dart';

class RequestSignOutCode {
  const RequestSignOutCode(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call(String email) => _repository.requestSignOutCode(email);
}

class ConfirmSignOut {
  const ConfirmSignOut(this._repository, this._signOut);

  final AuthRepository _repository;
  final SignOut _signOut;

  /// Ends the session if [code] is right. On any failure nothing is signed out.
  Future<Result<void>> call(String code) async {
    final result = await _repository.confirmSignOutCode(code);
    if (result is Ok<void>) await _signOut();
    return result;
  }
}
