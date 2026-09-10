/// The last step of sign-up: name and password.
///
/// Only what an account genuinely needs is required. Phone is optional, because asking
/// for it here would cost more sign-ups than the number is worth.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/setup_scaffold.dart';
import '../../../../routing/routes.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_error.dart';

class CreateProfilePage extends ConsumerStatefulWidget {
  const CreateProfilePage({super.key});

  @override
  ConsumerState<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends ConsumerState<CreateProfilePage> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _showPassword = false;
  String? _firstError, _lastError, _passwordError, _confirmError;

  @override
  void dispose() {
    for (final c in [_first, _last, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _firstError = _first.text.trim().isEmpty ? 'Ismingizni kiriting.' : null;
      _lastError = _last.text.trim().isEmpty ? 'Familiyangizni kiriting.' : null;
      _passwordError = _password.text.length < 8
          ? 'Parol kamida 8 ta belgidan iborat bo‘lsin.'
          : null;
      _confirmError =
          _confirm.text != _password.text ? 'Parollar mos kelmadi.' : null;
    });
    return [_firstError, _lastError, _passwordError, _confirmError]
        .every((e) => e == null);
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    final ok = await ref.read(authControllerProvider.notifier).register(
          password: _password.text,
          firstName: _first.text.trim(),
          lastName: _last.text.trim(),
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        );
    // Registration establishes the session, so the flow ends here rather than sending
    // the person to a login screen they have just earned the right to skip.
    if (ok && mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final colors = context.vocaColors;
    final text = context.vocaText;

    return SetupScaffold(
      title: 'Profilingizni to‘ldiring',
      primaryLabel: 'Akkaunt yaratish',
      isBusy: state.isBusy,
      onPrimary: state.isBusy ? null : () => unawaited(_submit()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthErrorBanner(failure: state.failure),

          // The verified address, shown but not editable: changing it here would discard
          // the verification that was just completed.
          Container(
            padding: const EdgeInsets.all(VocaSpacing.sm),
            decoration: BoxDecoration(
              color: colors.successMuted,
              borderRadius: VocaRadius.mediumAll,
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 18, color: colors.onSuccessMuted),
                const SizedBox(width: VocaSpacing.xs),
                Expanded(
                  child: Text(
                    state.email ?? '',
                    style: text.bodyMedium.copyWith(color: colors.onSuccessMuted),
                  ),
                ),
                Text('Tasdiqlangan',
                    style: text.caption.copyWith(color: colors.onSuccessMuted)),
              ],
            ),
          ),
          const SizedBox(height: VocaSpacing.lg),

          AppTextField(
            label: 'Ism',
            controller: _first,
            errorText: _firstError,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: VocaSpacing.md),
          AppTextField(
            label: 'Familiya',
            controller: _last,
            errorText: _lastError,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: VocaSpacing.md),
          AppTextField(
            label: 'Telefon raqami',
            helperText: 'Ixtiyoriy',
            controller: _phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: VocaSpacing.md),
          AppTextField(
            label: 'Parol',
            controller: _password,
            obscureText: !_showPassword,
            errorText: _passwordError,
            helperText: 'Kamida 8 ta belgi',
            textInputAction: TextInputAction.next,
            suffixIcon: IconButton(
              // Being able to see what was typed prevents more failed sign-ups than
              // hiding it prevents shoulder surfing.
              onPressed: () => setState(() => _showPassword = !_showPassword),
              icon: Icon(_showPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              tooltip: _showPassword ? 'Parolni yashirish' : 'Parolni ko‘rsatish',
            ),
          ),
          const SizedBox(height: VocaSpacing.md),
          AppTextField(
            label: 'Parolni tasdiqlang',
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
