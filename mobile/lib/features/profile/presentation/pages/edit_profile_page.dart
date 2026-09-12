/// Editing the profile: the picture, the name and the number.
///
/// The address is shown but not editable. It is how the person signs in and where every
/// confirmation code goes, so changing it needs a flow that proves the new one first.
///
/// The picture keeps its own endpoint, as it does at sign-up: the name is saved first, and
/// a photo that fails to upload is reported without losing the rest of the edit.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/avatar_picker.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/setup_scaffold.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/widgets/auth_error.dart';
import '../controllers/profile_controller.dart';
import '../../../../l10n/l10n.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  static const pageKey = ValueKey('edit-profile-page');

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();

  /// Filled from the profile once, so typing is never overwritten by a refresh.
  var _loaded = false;

  File? _avatar;
  String? _firstError, _lastError, _phoneError;
  Failure? _failure;
  var _busy = false;

  @override
  void dispose() {
    for (final c in [_first, _last, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  /// The same rule the server applies, checked while the keyboard is still open. The
  /// server checks it again: a rule that only exists in the app is not a rule.
  String? _phoneProblem(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return context.l10n.phoneRequired;
    final local = digits.length == 9;
    final withLeadingZero = digits.length == 10 && digits.startsWith('0');
    final international = digits.length >= 11 && digits.length <= 15;
    if (local || withLeadingZero || international) return null;
    return context.l10n.phoneInvalid;
  }

  bool _validate() {
    setState(() {
      _firstError = _first.text.trim().isEmpty
          ? context.l10n.firstNameRequired
          : null;
      _lastError = _last.text.trim().isEmpty
          ? context.l10n.lastNameRequired
          : null;
      _phoneError = _phoneProblem(_phone.text);
    });
    return [_firstError, _lastError, _phoneError].every((e) => e == null);
  }

  Future<void> _save() async {
    if (_busy || !_validate()) return;
    setState(() {
      _busy = true;
      _failure = null;
    });

    final result = await ref.read(updateProfileProvider)(
      firstName: _first.text.trim(),
      lastName: _last.text.trim(),
      phone: _phone.text.trim(),
    );
    if (!mounted) return;

    if (result case Err(:final failure)) {
      setState(() {
        _busy = false;
        _failure = failure;
      });
      return;
    }

    // The picture is a separate endpoint, as it is at sign-up. A failure here does not
    // undo the name that was just saved; it is reported and the edit stands.
    var photoFailed = false;
    if (_avatar != null) {
      photoFailed = !await ref
          .read(authControllerProvider.notifier)
          .uploadAvatar(_avatar!.path);
    }
    if (!mounted) return;

    ref.invalidate(profileProvider);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          photoFailed
              ? context.l10n.avatarUploadFailed
              : context.l10n.profileSaved,
        ),
      ),
    );
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    final l = context.l10n;
    final profile = ref.watch(profileProvider).valueOrNull;

    if (!_loaded && profile != null) {
      _loaded = true;
      _first.text = profile.firstName ?? '';
      _last.text = profile.lastName ?? '';
      _phone.text = profile.phone ?? '';
    }

    return KeyedSubtree(
      key: EditProfilePage.pageKey,
      child: SetupScaffold(
        title: l.editProfile,
        primaryLabel: l.saveChanges,
        isBusy: _busy,
        onPrimary: _busy ? null : () => unawaited(_save()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthErrorBanner(failure: _failure),
            Center(
              child: AvatarPicker(
                file: _avatar,
                enabled: !_busy,
                onChanged: (f) => setState(() => _avatar = f),
              ),
            ),
            const SizedBox(height: VocaSpacing.xl),
            AppTextField(
              label: l.firstNameLabel,
              controller: _first,
              enabled: !_busy,
              errorText: _firstError,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: VocaSpacing.md),
            AppTextField(
              label: l.lastNameLabel,
              controller: _last,
              enabled: !_busy,
              errorText: _lastError,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: VocaSpacing.md),
            AppTextField(
              label: l.phoneLabel,
              controller: _phone,
              enabled: !_busy,
              errorText: _phoneError,
              helperText: l.phoneHelper,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => unawaited(_save()),
            ),
            const SizedBox(height: VocaSpacing.xl),
            Text(l.emailLabel, style: text.label),
            const SizedBox(height: VocaSpacing.xs),
            GlassSurface(
              blur: false,
              showShadow: false,
              padding: const EdgeInsets.all(VocaSpacing.md),
              borderRadius: BorderRadius.circular(VocaRadius.large),
              child: Row(
                children: [
                  Icon(Icons.mail_outline_rounded, color: colors.textSecondary),
                  const SizedBox(width: VocaSpacing.md),
                  Expanded(
                    child: Text(
                      profile?.email ?? '',
                      style: text.body.copyWith(color: colors.textSecondary),
                    ),
                  ),
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: VocaSpacing.xs),
            Text(
              l.emailNotEditable,
              style: text.caption.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
