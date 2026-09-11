/// Ends the session and returns to the way in.
///
/// One widget used by both Profile and Settings, so there is exactly one sign-out in the
/// app and it always ends both sessions: Voca's, and the Google one. Leaving the Google
/// session behind would make the next sign-in silently reuse this account.
///
/// It always asks first. A guest, who has no mailbox, is then signed out. Anyone else
/// confirms with a code sent to their account's address, and the server ends the session
/// before anything here is cleared (sign_out_flow.dart).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_action_button.dart';
import '../../../../routing/routes.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import 'sign_out_flow.dart';

class SignOutButton extends ConsumerStatefulWidget {
  const SignOutButton({super.key});

  @override
  ConsumerState<SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends ConsumerState<SignOutButton> {
  // A second tap while the conversation is open must not start a second one.
  bool _open = false;

  // Only the guest path clears storage from here, so only it shows a spinner.
  bool _busy = false;

  Future<Profile?> _profileOrNull() async {
    try {
      return await ref.read(profileProvider.future);
    } catch (_) {
      return null;
    }
  }

  Future<void> _signOut() async {
    if (_open) return;
    _open = true;
    try {
      // Whether there is a mailbox to confirm from. If the profile cannot be read, the
      // account is treated as having one: signing out without the check is the one thing
      // this flow must never fall into by accident.
      final profile = await _profileOrNull();
      final isGuest =
          profile != null && (profile.isGuest || profile.email == null);
      if (!mounted) return;

      final confirmed = await askToSignOut(context, isGuest: isGuest);
      if (!confirmed || !mounted) return;

      if (isGuest) {
        setState(() => _busy = true);
        await ref.read(signOutProvider)();
      } else if (!await verifySignOutByEmail(context)) {
        return;
      }
      if (mounted) context.go(Routes.authEntry);
    } finally {
      _open = false;
      if (mounted && _busy) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    return GlassActionButton(
      label: 'Hisobdan chiqish',
      icon: Icon(Icons.logout_rounded, size: 20, color: colors.error),
      isLoading: _busy,
      onPressed: _busy ? null : () => unawaited(_signOut()),
    );
  }
}
