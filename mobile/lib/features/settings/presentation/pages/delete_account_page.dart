/// Deleting the account, confirmed from its own mailbox.
///
/// Deliberately the same conversation as the confirmed sign-out: the address the account
/// already has, a code sent there, and nothing destroyed until the server has accepted it.
/// The difference is what it costs, so this one asks a second time, in plain words, after
/// the code and before the call.
///
/// The address is shown, not typed. It comes from the profile, and the server checks it
/// against the session anyway; offering a text field would invite somebody to enter an
/// address that could only ever be refused.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/code_input.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/setup_scaffold.dart';
import '../../../../routing/routes.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/widgets/auth_error.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../../l10n/l10n.dart';

enum _Step { email, code }

class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  static const pageKey = ValueKey('delete-account-page');

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  var _step = _Step.email;
  var _code = '';
  Failure? _failure;
  var _busy = false;

  // The wait the server enforces between codes, shown rather than discovered.
  var _cooldown = 0;
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

  Future<void> _send(String email) async {
    if (_busy || email.isEmpty) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    final result = await ref.read(requestAccountDeletionCodeProvider)(email);
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (result) {
        case Ok():
          _step = _Step.code;
        case Err(:final failure):
          _failure = failure;
      }
    });
    if (result is Ok<void>) _startCooldown();
  }

  /// The code is not spent here. The server checks it and deletes in one call, so it is
  /// held until the last question has been answered and nothing is destroyed by a person
  /// who typed six digits and then changed their mind.
  Future<void> _continue() async {
    if (_busy || _code.length != 6) return;
    final sure = await _askToDelete(context);
    if (!sure || !mounted) return;

    setState(() {
      _busy = true;
      _failure = null;
    });
    final result = await ref.read(deleteAccountProvider)(_code);
    if (!mounted) return;
    switch (result) {
      case Ok():
        context.go(Routes.authEntry);
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
    final l = context.l10n;
    final email = ref.watch(profileProvider).valueOrNull?.email ?? '';

    return KeyedSubtree(
      key: DeleteAccountPage.pageKey,
      child: SetupScaffold(
        title: l.deleteAccount,
        subtitle: l.deleteAccountIntro,
        primaryLabel: _step == _Step.email ? l.sendCode : l.confirmAction,
        isBusy: _busy,
        onPrimary: _busy
            ? null
            : _step == _Step.email
            ? () => unawaited(_send(email))
            : (_code.length == 6 ? () => unawaited(_continue()) : null),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Warning(),
            const SizedBox(height: VocaSpacing.lg),
            AuthErrorBanner(failure: _failure),
            if (_step == _Step.email) ...[
              Text(
                l.deleteAccountEmailNote,
                style: text.body.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: VocaSpacing.md),
              // Shown, not typed: the account's own address is the only one the server
              // will accept.
              GlassSurface(
                blur: false,
                padding: const EdgeInsets.all(VocaSpacing.md),
                borderRadius: BorderRadius.circular(VocaRadius.large),
                child: Row(
                  children: [
                    Icon(
                      Icons.mail_outline_rounded,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: VocaSpacing.md),
                    Expanded(
                      child: Text(
                        email,
                        style: text.body.copyWith(color: colors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text.rich(
                TextSpan(
                  text: l.codeSentPrefix,
                  style: text.body.copyWith(color: colors.textSecondary),
                  children: [
                    TextSpan(
                      text: email,
                      style: text.body.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: VocaSpacing.md),
              CodeInput(
                hasError: _failure != null,
                enabled: !_busy,
                onCompleted: (code) => setState(() => _code = code),
              ),
              const SizedBox(height: VocaSpacing.sm),
              Center(
                child: VocaTextButton(
                  label: _cooldown > 0 ? l.resendIn(_cooldown) : l.resend,
                  onPressed: _cooldown > 0 || _busy
                      ? null
                      : () => unawaited(_send(email)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// What deletion costs, before anything is set in motion.
///
/// Carries an icon and its own words as well as the error tint, so it still reads as a
/// warning where the tint is hard to see: in the light theme, or to somebody who cannot
/// tell it from the page.
class _Warning extends StatelessWidget {
  const _Warning();

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;

    return GlassSurface(
      edgeGlow: false,
      blur: false,
      showShadow: false,
      tint: colors.errorMuted,
      borderRadius: VocaRadius.mediumAll,
      padding: const EdgeInsets.all(VocaSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: colors.onErrorMuted,
          ),
          const SizedBox(width: VocaSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.deleteConfirmWarning,
              style: text.bodyMedium.copyWith(color: colors.onErrorMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// The last question. True only when the person says so in as many words.
Future<bool> _askToDelete(BuildContext context) async {
  final answer = await showDialog<bool>(
    context: context,
    builder: (_) => const _ConfirmDeleteDialog(),
  );
  return answer ?? false;
}

class _ConfirmDeleteDialog extends StatelessWidget {
  const _ConfirmDeleteDialog();

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    final l = context.l10n;

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
              l.deleteConfirmTitle,
              style: text.title.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: VocaSpacing.sm),
            Text(
              l.deleteConfirmQuestion,
              style: text.body.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: VocaSpacing.xs),
            Text(
              l.deleteConfirmWarning,
              style: text.bodyMedium.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: VocaSpacing.lg),
            PrimaryButton(
              label: l.deleteConfirmYes,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: VocaSpacing.xs),
            Center(
              child: VocaTextButton(
                label: l.answerNo,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
