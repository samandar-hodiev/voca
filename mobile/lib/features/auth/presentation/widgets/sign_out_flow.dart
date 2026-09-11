/// The sign-out conversation.
///
/// First a confirmation. Then, for an account with an address, a code sent to that
/// address, and the session ends only once the server has accepted it. Closing the
/// dialog or the sheet at any point leaves the person signed in.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/code_input.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_error.dart';
import '../../../../l10n/l10n.dart';

/// Asks whether the person really wants to sign out. True only when they confirm.
Future<bool> askToSignOut(BuildContext context, {required bool isGuest}) async {
  final answer = await showDialog<bool>(
    context: context,
    builder: (_) => _ConfirmDialog(isGuest: isGuest),
  );
  return answer ?? false;
}

/// Sends a code to the account's own address and waits for it. True once the server has
/// accepted the code and the session has ended.
Future<bool> verifySignOutByEmail(BuildContext context) async {
  final done = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _VerifySheet(),
  );
  return done ?? false;
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({required this.isGuest});

  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(VocaSpacing.lg),
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.signOut,
              style: text.title.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: VocaSpacing.sm),
            Text(
              context.l10n.signOutQuestion,
              style: text.body.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: VocaSpacing.xs),
            // A guest is told what they lose; anyone else, what happens next.
            Text(
              isGuest
                  ? context.l10n.signOutGuestWarning
                  : context.l10n.signOutCodeNote,
              style: text.bodyMedium.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: VocaSpacing.lg),
            PrimaryButton(
              label: context.l10n.signOutConfirm,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: VocaSpacing.xs),
            Center(
              child: VocaTextButton(
                label: context.l10n.cancel,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Step { email, code }

class _VerifySheet extends ConsumerStatefulWidget {
  const _VerifySheet();

  @override
  ConsumerState<_VerifySheet> createState() => _VerifySheetState();
}

class _VerifySheetState extends ConsumerState<_VerifySheet> {
  final _email = TextEditingController();
  var _step = _Step.email;
  var _sentTo = '';
  Failure? _failure;
  var _busy = false;

  // The wait the server enforces between codes, shown rather than discovered.
  var _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
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

  Future<void> _send(String email) async {
    if (email.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    final result = await ref.read(requestSignOutCodeProvider)(email);
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (result) {
        case Ok():
          _step = _Step.code;
          _sentTo = email;
        case Err(:final failure):
          _failure = failure;
      }
    });
    if (result is Ok<void>) _startCooldown();
  }

  Future<void> _confirm(String code) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    final result = await ref.read(confirmSignOutProvider)(code);
    if (!mounted) return;
    switch (result) {
      case Ok():
        Navigator.of(context).pop(true);
      case Err(:final failure):
        setState(() {
          _busy = false;
          _failure = failure;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;

    return Padding(
      // Rides up with the keyboard, so the field and the button stay in view.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(VocaSpacing.md),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.signOutVerifyTitle,
                  style: text.title.copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: VocaSpacing.xs),
                if (_step == _Step.email) ...[
                  Text(
                    context.l10n.signOutEnterEmail,
                    style: text.body.copyWith(color: colors.textSecondary),
                  ),
                  const SizedBox(height: VocaSpacing.md),
                  AuthErrorBanner(failure: _failure),
                  TextField(
                    key: const ValueKey('sign-out-email'),
                    controller: _email,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (value) => unawaited(_send(value.trim())),
                    decoration: InputDecoration(
                      hintText: context.l10n.emailHint,
                    ),
                  ),
                  const SizedBox(height: VocaSpacing.md),
                  PrimaryButton(
                    label: context.l10n.sendCode,
                    isLoading: _busy,
                    onPressed: _busy
                        ? null
                        : () => unawaited(_send(_email.text.trim())),
                  ),
                ] else ...[
                  Text.rich(
                    TextSpan(
                      text: context.l10n.codeSentPrefix,
                      style: text.body.copyWith(color: colors.textSecondary),
                      children: [
                        TextSpan(
                          text: _sentTo,
                          style: text.body.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: VocaSpacing.md),
                  AuthErrorBanner(failure: _failure),
                  CodeInput(
                    hasError: _failure != null,
                    enabled: !_busy,
                    onCompleted: (code) => unawaited(_confirm(code)),
                  ),
                  const SizedBox(height: VocaSpacing.sm),
                  Center(
                    child: VocaTextButton(
                      label: _cooldown > 0
                          ? context.l10n.resendIn(_cooldown)
                          : context.l10n.resend,
                      onPressed: _cooldown > 0 || _busy
                          ? null
                          : () => unawaited(_send(_sentTo)),
                    ),
                  ),
                ],
                const SizedBox(height: VocaSpacing.xs),
                Center(
                  child: VocaTextButton(
                    label: context.l10n.cancel,
                    onPressed: _busy
                        ? null
                        : () => Navigator.of(context).pop(false),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
