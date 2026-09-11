/// Six-digit code entry for sign-up.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/code_input.dart';
import '../../../../core/widgets/setup_scaffold.dart';
import '../../../../routing/routes.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_error.dart';
import '../../../../l10n/l10n.dart';

class EmailVerifyPage extends ConsumerStatefulWidget {
  const EmailVerifyPage({super.key});

  @override
  ConsumerState<EmailVerifyPage> createState() => _EmailVerifyPageState();
}

class _EmailVerifyPageState extends ConsumerState<EmailVerifyPage> {
  String _code = '';

  // A cooldown on resend, mirroring the server's own limit. Showing the wait is kinder
  // than letting someone tap into a rejection.
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _verify() async {
    if (_code.length != 6) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .verifyEmail(_code);
    if (ok && mounted) unawaited(context.push(Routes.createProfile));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final colors = context.vocaColors;
    final text = context.vocaText;

    return SetupScaffold(
      title: context.l10n.verifyEmailTitle,
      primaryLabel: context.l10n.confirmAction,
      isBusy: state.isBusy,
      onPrimary: _code.length == 6 && !state.isBusy ? _verify : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: context.l10n.codeSentPrefix,
              style: text.body.copyWith(color: colors.textSecondary),
              children: [
                TextSpan(
                  text: state.email ?? '',
                  style: text.body.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: VocaSpacing.xl),
          AuthErrorBanner(failure: state.failure),
          CodeInput(
            hasError: state.failure != null,
            enabled: !state.isBusy,
            onCompleted: (code) {
              setState(() => _code = code);
              // Fire and forget: the field is complete, so verification starts on its
              // own rather than making the person reach for the button.
              unawaited(_verify());
            },
          ),
          const SizedBox(height: VocaSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.l10n.codeNotReceived,
                style: text.bodyMedium.copyWith(color: colors.textSecondary),
              ),
              TextButton(
                onPressed: _cooldown > 0 || state.isBusy
                    ? null
                    : () async {
                        await ref
                            .read(authControllerProvider.notifier)
                            .resendCode();
                        _startCooldown();
                      },
                child: Text(
                  _cooldown > 0
                      ? context.l10n.resendIn(_cooldown)
                      : context.l10n.resend,
                ),
              ),
            ],
          ),
          Center(
            child: TextButton(
              onPressed: state.isBusy ? null : () => context.pop(),
              child: Text(context.l10n.useAnotherEmail),
            ),
          ),
        ],
      ),
    );
  }
}
