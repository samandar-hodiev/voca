/// Where the first-launch flow ends and an identity begins.
///
/// Deliberately sparse: two ways forward and one way past. Apple sign-in is designed for
/// but not built, because it needs an Apple Developer configuration that does not exist
/// yet, and a button that cannot work is worse than no button.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/setup_scaffold.dart';
import '../../../../routing/routes.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_error.dart';

class AuthEntryPage extends ConsumerWidget {
  const AuthEntryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    final colors = context.vocaColors;
    final text = context.vocaText;

    return SetupScaffold(
      title: 'Voca akkauntingizni yarating',
      subtitle: 'Natijalaringiz saqlanadi va barcha qurilmalarda mavjud bo‘ladi.',
      primaryLabel: 'Pochta bilan davom etish',
      onPrimary: state.isBusy ? null : () => context.push(Routes.emailSignUp),
      isBusy: false,
      footer: TextButton(
        onPressed: state.isBusy ? null : () => context.push(Routes.login),
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
      child: Column(
        children: [
          AuthErrorBanner(failure: state.failure),
          SecondaryButton(
            label: 'Mehmon sifatida davom etish',
            isLoading: state.isBusy,
            onPressed: state.isBusy
                ? null
                : () async {
                    final ok = await ref.read(authControllerProvider.notifier)
                        .continueAsGuest();
                    if (ok && context.mounted) context.go(Routes.home);
                  },
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
