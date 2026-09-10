/// Where the first-launch flow ends and an identity begins.
///
/// The choices are stacked in order of how many people will take them, and they are all
/// glass rather than one being filled: they are alternatives to one another, not a
/// hierarchy, and making one solid would say it is the right answer.
///
/// A method whose server-side credentials are missing renders disabled with a note rather
/// than being hidden. Hiding it leaves people wondering whether it is coming; showing it
/// as tappable would be a lie.
///
/// Sign in with Apple is absent entirely rather than shown disabled: there is no Apple
/// Developer account yet, so there is no date to promise. It returns when the account
/// exists.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/config/remote_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/brand_marks.dart';
import '../../../../core/widgets/glass_action_button.dart';
import '../../../../core/widgets/setup_scaffold.dart';
import '../../../../routing/routes.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_error.dart';

class AuthEntryPage extends ConsumerStatefulWidget {
  const AuthEntryPage({super.key});

  @override
  ConsumerState<AuthEntryPage> createState() => _AuthEntryPageState();
}

class _AuthEntryPageState extends ConsumerState<AuthEntryPage> {
  bool _googleBusy = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _googleBusy = true);
    try {
      final account = await GoogleSignIn().signIn();
      if (account == null) return; // The person dismissed the sheet.

      final tokens = await account.authentication;
      final idToken = tokens.idToken;
      if (idToken == null) return;

      // The token goes to our backend, which verifies it against Google's keys. The app
      // never decides whether a sign-in is genuine.
      final ok = await ref
          .read(authControllerProvider.notifier)
          .signInWithGoogle(idToken, first: account.displayName ?? '');
      if (ok && mounted) context.go(Routes.home);
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final capabilities = ref.watch(capabilitiesProvider);
    final colors = context.vocaColors;
    final text = context.vocaText;

    // Until the server answers, optional methods stay disabled. Enabling them optimistically
    // would show a working button that fails on the first tap.
    final caps = capabilities.valueOrNull ?? const Capabilities();
    final busy = state.isBusy || _googleBusy;

    return SetupScaffold(
      title: 'Voca akkauntingizni yarating',
      subtitle: 'Natijalaringiz saqlanadi va barcha qurilmalarda mavjud bo‘ladi.',
      child: Column(
        children: [
          AuthErrorBanner(failure: state.failure),

          GlassActionButton(
            label: 'Google bilan kirish',
            icon: const GoogleMark(),
            isLoading: _googleBusy,
            unavailableNote: caps.googleSignIn ? null : 'Tez orada',
            onPressed: caps.googleSignIn && !busy ? () => unawaited(_signInWithGoogle()) : null,
          ),
          const SizedBox(height: VocaSpacing.sm),

          GlassActionButton(
            label: 'Email bilan kirish',
            icon: Icon(Icons.mail_outline_rounded, size: 20, color: colors.primary),
            onPressed: busy ? null : () => unawaited(context.push(Routes.emailSignUp)),
          ),
          const SizedBox(height: VocaSpacing.sm),

          const SizedBox(height: VocaSpacing.lg),

          TextButton(
            onPressed: busy ? null : () => unawaited(context.push(Routes.login)),
            child: Text.rich(
              TextSpan(
                text: 'Akkauntingiz bormi? ',
                style: text.bodyMedium.copyWith(color: colors.textSecondary),
                children: [
                  TextSpan(
                    text: 'Kirish',
                    style: text.bodyMedium.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: VocaSpacing.md),

          GlassActionButton(
            label: 'Mehmon sifatida kirish',
            icon: Icon(Icons.person_outline_rounded, size: 20, color: colors.textSecondary),
            isLoading: state.isBusy,
            onPressed: busy
                ? null
                : () async {
                    final ok = await ref
                        .read(authControllerProvider.notifier)
                        .continueAsGuest();
                    if (ok && context.mounted) context.go(Routes.home);
                  },
          ),
          const SizedBox(height: VocaSpacing.sm),
          Text(
            'Mehmon sifatida ham mashq qilishingiz mumkin. '
            'Keyinroq akkaunt yaratsangiz, natijalaringiz saqlanib qoladi.',
            style: text.caption.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
