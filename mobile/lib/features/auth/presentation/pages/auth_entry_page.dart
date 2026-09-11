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

import '../../../../core/config/firebase_init.dart';
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

/// Which way in is currently running.
///
/// One value rather than a flag per button, because only one can be in flight at a time
/// and the spinner has to sit on the button that was actually tapped. The controller's
/// shared busy flag cannot answer that: it says something is happening, not what.
enum _Attempt { google, guest }

class _AuthEntryPageState extends ConsumerState<AuthEntryPage> {
  _Attempt? _attempt;

  /// Runs one way in, showing the spinner on its own button.
  ///
  /// The screen owns none of the sequence. Picker, Firebase, backend verification and
  /// session storage all live behind the controller, so this only guards against a second
  /// tap and decides where to go afterwards.
  Future<void> _start(_Attempt attempt, Future<bool> Function() run) async {
    if (_attempt != null) return;
    setState(() => _attempt = attempt);
    try {
      final ok = await run();
      if (ok && mounted) context.go(Routes.home);
    } finally {
      if (mounted) setState(() => _attempt = null);
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
    final busy = state.isBusy || _attempt != null;

    // Both halves have to be there. The server decides whether it can verify a token, and
    // the app decides whether it can produce one: without the platform configuration file
    // Firebase never started, and a button that opens a picker it cannot finish is worse
    // than one that says "coming soon".
    final googleReady = caps.googleSignIn && isFirebaseReady;

    return SetupScaffold(
      title: 'Voca akkauntingizni yarating',
      subtitle:
          'Natijalaringiz saqlanadi va barcha qurilmalarda mavjud bo‘ladi.',
      child: Column(
        children: [
          AuthErrorBanner(failure: state.failure),

          GlassActionButton(
            label: 'Google bilan kirish',
            icon: const GoogleMark(),
            isLoading: _attempt == _Attempt.google,
            unavailableNote: googleReady ? null : 'Tez orada',
            onPressed: googleReady && !busy
                ? () => unawaited(
                    _start(
                      _Attempt.google,
                      ref
                          .read(authControllerProvider.notifier)
                          .signInWithGoogle,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: VocaSpacing.sm),

          GlassActionButton(
            label: 'Email bilan kirish',
            icon: Icon(
              Icons.mail_outline_rounded,
              size: 20,
              color: colors.primary,
            ),
            onPressed: busy
                ? null
                : () => unawaited(context.push(Routes.emailSignUp)),
          ),
          const SizedBox(height: VocaSpacing.sm),

          const SizedBox(height: VocaSpacing.lg),

          TextButton(
            onPressed: busy
                ? null
                : () => unawaited(context.push(Routes.login)),
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
            icon: Icon(
              Icons.person_outline_rounded,
              size: 20,
              color: colors.textSecondary,
            ),
            isLoading: _attempt == _Attempt.guest,
            onPressed: busy
                ? null
                : () => unawaited(
                    _start(
                      _Attempt.guest,
                      ref.read(authControllerProvider.notifier).continueAsGuest,
                    ),
                  ),
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
