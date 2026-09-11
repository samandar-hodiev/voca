/// Collects the address a verification code will be sent to.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/widgets/setup_scaffold.dart';
import '../../../../routing/routes.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_error.dart';

class EmailSignUpPage extends ConsumerStatefulWidget {
  const EmailSignUpPage({super.key});

  @override
  ConsumerState<EmailSignUpPage> createState() => _EmailSignUpPageState();
}

class _EmailSignUpPageState extends ConsumerState<EmailSignUpPage> {
  final _controller = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// A deliberately loose check.
  ///
  /// The point is to catch a typo before spending a round trip, not to police what a
  /// valid address is; the server decides that, and over-strict client rules reject real
  /// addresses.
  bool _looksLikeEmail(String v) {
    final trimmed = v.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
  }

  /// Whether the last failure was "this address already has an account".
  bool _isTaken(Object? failure) =>
      failure is ApiFailure && failure.code == 'EMAIL_ALREADY_EXISTS';

  Future<void> _submit() async {
    final email = _controller.text.trim();
    if (!_looksLikeEmail(email)) {
      setState(() => _localError = 'Pochta manzilini to‘g‘ri kiriting.');
      return;
    }
    setState(() => _localError = null);

    final ok = await ref.read(authControllerProvider.notifier)
        .startEmailVerification(email);
    if (ok && mounted) unawaited(context.push(Routes.emailVerify));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return SetupScaffold(
      title: 'Pochtangizni kiriting',
      subtitle: 'Tasdiqlash uchun 6 xonali kod yuboramiz.',
      primaryLabel: 'Davom etish',
      isBusy: state.isBusy,
      onPrimary: state.isBusy ? null : _submit,
      child: Column(
        children: [
          AuthErrorBanner(failure: state.failure),

          // An address that already has an account is a dead end on this screen, so the
          // way out is offered here rather than leaving the person to find it.
          if (_isTaken(state.failure)) ...[
            SecondaryButton(
              label: 'Shu pochta bilan kirish',
              icon: Icons.login_rounded,
              onPressed: state.isBusy
                  ? null
                  : () => unawaited(context.push(Routes.login)),
            ),
            const SizedBox(height: VocaSpacing.md),
          ],

          AppTextField(
            label: 'Elektron pochta',
            hint: 'siz@example.com',
            controller: _controller,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofocus: true,
            errorText: _localError,
            onSubmitted: (_) => unawaited(_submit()),
          ),
        ],
      ),
    );
  }
}
