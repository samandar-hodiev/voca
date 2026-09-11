/// Password recovery: the three screens that put someone back into their account.
///
/// They share the flow of sign-up verification on purpose, because the security rules are
/// identical and a person who has just done one recognises the other.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/code_input.dart';
import '../../../../core/widgets/setup_scaffold.dart';
import '../../../../routing/routes.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_error.dart';
import '../../../../l10n/l10n.dart';

/// Step one: which address.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await ref
        .read(authControllerProvider.notifier)
        .forgotPassword(_email.text.trim());
    if (ok && mounted) unawaited(context.push(Routes.forgotVerify));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return SetupScaffold(
      title: context.l10n.resetPasswordTitle,
      subtitle: context.l10n.resetPasswordSubtitle,
      primaryLabel: context.l10n.sendCode,
      isBusy: state.isBusy,
      onPrimary: state.isBusy ? null : () => unawaited(_submit()),
      child: Column(
        children: [
          AuthErrorBanner(failure: state.failure),
          AppTextField(
            label: context.l10n.emailLabel,
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofocus: true,
            onSubmitted: (_) => unawaited(_submit()),
          ),
        ],
      ),
    );
  }
}

/// Step two: the code.
class ForgotVerifyPage extends ConsumerStatefulWidget {
  const ForgotVerifyPage({super.key});

  @override
  ConsumerState<ForgotVerifyPage> createState() => _ForgotVerifyPageState();
}

class _ForgotVerifyPageState extends ConsumerState<ForgotVerifyPage> {
  String _code = '';

  Future<void> _verify() async {
    if (_code.length != 6) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .verifyPasswordCode(_code);
    if (ok && mounted) unawaited(context.push(Routes.newPassword));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final colors = context.vocaColors;
    final text = context.vocaText;

    return SetupScaffold(
      title: context.l10n.enterCodeTitle,
      primaryLabel: context.l10n.confirmAction,
      isBusy: state.isBusy,
      onPrimary: _code.length == 6 && !state.isBusy
          ? () => unawaited(_verify())
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.codeSentToEmail(state.email ?? ''),
            style: text.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: VocaSpacing.xl),
          AuthErrorBanner(failure: state.failure),
          CodeInput(
            hasError: state.failure != null,
            enabled: !state.isBusy,
            onCompleted: (code) {
              setState(() => _code = code);
              unawaited(_verify());
            },
          ),
        ],
      ),
    );
  }
}

/// Step three: the new password.
class NewPasswordPage extends ConsumerStatefulWidget {
  const NewPasswordPage({super.key});

  @override
  ConsumerState<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends ConsumerState<NewPasswordPage> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _showPassword = false;
  String? _passwordError, _confirmError;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _passwordError = _password.text.length < 8
          ? context.l10n.passwordTooShort
          : null;
      _confirmError = _confirm.text != _password.text
          ? context.l10n.passwordsDontMatch
          : null;
    });
    if (_passwordError != null || _confirmError != null) return;

    final ok = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(_password.text);
    // The reset signs the person in, so they land in the product rather than at a login
    // screen they would immediately pass through.
    if (ok && mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return SetupScaffold(
      title: context.l10n.newPassword,
      subtitle: context.l10n.newPasswordSubtitle,
      primaryLabel: context.l10n.saveAndSignIn,
      isBusy: state.isBusy,
      onPrimary: state.isBusy ? null : () => unawaited(_submit()),
      child: Column(
        children: [
          AuthErrorBanner(failure: state.failure),
          AppTextField(
            label: context.l10n.newPassword,
            controller: _password,
            obscureText: !_showPassword,
            errorText: _passwordError,
            helperText: context.l10n.passwordHelper,
            autofocus: true,
            textInputAction: TextInputAction.next,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _showPassword = !_showPassword),
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              tooltip: _showPassword
                  ? context.l10n.passwordHide
                  : context.l10n.passwordShow,
            ),
          ),
          const SizedBox(height: VocaSpacing.md),
          AppTextField(
            label: context.l10n.passwordConfirmLabel,
            controller: _confirm,
            obscureText: !_showPassword,
            errorText: _confirmError,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => unawaited(_submit()),
          ),
        ],
      ),
    );
  }
}
