/// Email and password sign-in.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/setup_scaffold.dart';
import '../../../../routing/routes.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_error.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await ref.read(authControllerProvider.notifier)
        .login(_email.text.trim(), _password.text);
    if (ok && mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final canSubmit = _email.text.trim().isNotEmpty && _password.text.isNotEmpty;

    return SetupScaffold(
      title: 'Xush kelibsiz',
      subtitle: 'Davom etish uchun kiring.',
      primaryLabel: 'Kirish',
      isBusy: state.isBusy,
      onPrimary: canSubmit && !state.isBusy ? () => unawaited(_submit()) : null,
      footer: TextButton(
        onPressed: state.isBusy ? null : () => context.push(Routes.forgotPassword),
        child: const Text('Parolni unutdingizmi?'),
      ),
      child: Column(
        children: [
          AuthErrorBanner(failure: state.failure),
          AppTextField(
            label: 'Elektron pochta',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofocus: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: VocaSpacing.md),
          AppTextField(
            label: 'Parol',
            controller: _password,
            obscureText: !_showPassword,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => unawaited(_submit()),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _showPassword = !_showPassword),
              icon: Icon(_showPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              tooltip: _showPassword ? 'Parolni yashirish' : 'Parolni ko‘rsatish',
            ),
          ),
        ],
      ),
    );
  }
}
