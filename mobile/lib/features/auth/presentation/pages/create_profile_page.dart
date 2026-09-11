/// The last step of sign-up: picture, name, phone and password.
///
/// Everything here is required. A picture and a number are what let a coach and a
/// classmate recognise somebody later, and collecting them afterwards means chasing
/// people who have already stopped thinking about their profile.
///
/// The picture is uploaded after the account exists, because the upload endpoint needs a
/// session. A failure there leaves the account in place and is reported rather than
/// silently swallowed.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/avatar_picker.dart';
import '../../../../core/widgets/setup_scaffold.dart';
import '../../../../routing/routes.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_error.dart';
import '../../../../core/widgets/glass_surface.dart';

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
  File? _avatar;
  String? _firstError, _lastError, _phoneError, _passwordError, _confirmError;
  String? _avatarError;

  @override
  void dispose() {
    for (final c in [_first, _last, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _avatarError = _avatar == null ? 'Profil rasmi kerak.' : null;
      _firstError = _first.text.trim().isEmpty ? 'Ismingizni kiriting.' : null;
      _lastError = _last.text.trim().isEmpty
          ? 'Familiyangizni kiriting.'
          : null;
      _phoneError = _phoneProblem(_phone.text);
      _passwordError = _password.text.length < 8
          ? 'Parol kamida 8 ta belgidan iborat bo‘lsin.'
          : null;
      _confirmError = _confirm.text != _password.text
          ? 'Parollar mos kelmadi.'
          : null;
    });
    return [
      _avatarError,
      _firstError,
      _lastError,
      _phoneError,
      _passwordError,
      _confirmError,
    ].every((e) => e == null);
  }

  /// Checks the number the same way the server does, so a mistake is caught while the
  /// keyboard is still open rather than after a round trip. The server checks it again
  /// regardless: a rule that only exists in the app is not a rule.
  String? _phoneProblem(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 'Telefon raqamni kiriting.';
    final local = digits.length == 9;
    final withLeadingZero = digits.length == 10 && digits.startsWith('0');
    final international = digits.length >= 11 && digits.length <= 15;
    if (local || withLeadingZero || international) return null;
    return 'Raqamni to‘g‘ri kiriting, masalan +998 90 123 45 67.';
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    final controller = ref.read(authControllerProvider.notifier);
    final ok = await controller.register(
      password: _password.text,
      firstName: _first.text.trim(),
      lastName: _last.text.trim(),
      phone: _phone.text.trim(),
    );
    if (!ok) return;

    // The account now exists and the session is established, which is what the upload
    // endpoint needs. A failed upload is reported but does not undo the account: making
    // somebody register twice because a photo did not go through would be worse.
    final uploaded = await controller.uploadAvatar(_avatar!.path);
    if (!mounted) return;
    if (!uploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Akkaunt yaratildi, lekin rasm yuklanmadi. '
            'Uni sozlamalardan qo‘shishingiz mumkin.',
          ),
        ),
      );
    }

    // Registration establishes the session, so the flow ends here rather than sending
    // the person to a login screen they have just earned the right to skip.
    context.go(Routes.home);
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

          Center(
            child: AvatarPicker(
              file: _avatar,
              enabled: !state.isBusy,
              errorText: _avatarError,
              onChanged: (f) => setState(() {
                _avatar = f;
                _avatarError = null;
              }),
            ),
          ),
          const SizedBox(height: VocaSpacing.lg),

          // The verified address, shown but not editable: changing it here would discard
          // the verification that was just completed.
          GlassSurface(
            edgeGlow: false,
            blur: false,
            showShadow: false,
            tint: colors.successMuted,
            borderRadius: VocaRadius.mediumAll,
            padding: const EdgeInsets.all(VocaSpacing.sm),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: colors.onSuccessMuted,
                ),
                const SizedBox(width: VocaSpacing.xs),
                Expanded(
                  child: Text(
                    state.email ?? '',
                    style: text.bodyMedium.copyWith(
                      color: colors.onSuccessMuted,
                    ),
                  ),
                ),
                Text(
                  'Tasdiqlangan',
                  style: text.caption.copyWith(color: colors.onSuccessMuted),
                ),
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
            helperText: 'Masalan +998 90 123 45 67',
            controller: _phone,
            errorText: _phoneError,
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
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              tooltip: _showPassword
                  ? 'Parolni yashirish'
                  : 'Parolni ko‘rsatish',
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
