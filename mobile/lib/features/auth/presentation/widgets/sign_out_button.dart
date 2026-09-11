/// Ends the session and returns to the way in.
///
/// One widget used by both Profile and Settings, so there is exactly one sign-out in the
/// app and it always ends both sessions: Voca's, and the Google one. Leaving the Google
/// session behind would make the next sign-in silently reuse this account.
///
/// Its own state so the spinner belongs to this button alone, and a second tap cannot
/// start a second sign-out while the first is still clearing storage.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_action_button.dart';
import '../../../../routing/routes.dart';

class SignOutButton extends ConsumerStatefulWidget {
  const SignOutButton({super.key});

  @override
  ConsumerState<SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends ConsumerState<SignOutButton> {
  bool _busy = false;

  Future<void> _signOut() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(signOutProvider)();
      if (mounted) context.go(Routes.authEntry);
    } finally {
      if (mounted) setState(() => _busy = false);
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
