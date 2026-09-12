/// Account settings.
///
/// The first thing here is appearance, because it is the one setting that changes what
/// every other screen looks like. Language, accent, difficulty and reminders follow as
/// their features arrive.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';

import 'package:go_router/go_router.dart';

import '../../../auth/presentation/widgets/sign_out_button.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/locale_controller.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/language_button.dart';
import '../../../../core/widgets/liquid_background.dart';
import '../../../../core/widgets/press_scale.dart';
import '../../../../routing/routes.dart';
import '../../../../core/widgets/selection_card.dart';
import '../../../../l10n/l10n.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const pageKey = ValueKey('settings-page');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    final mode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final l = context.l10n;

    return Scaffold(
      key: pageKey,
      body: LiquidBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageContainer(
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      if (Navigator.of(context).canPop())
                        VocaIconButton(
                          icon: Icons.arrow_back_rounded,
                          semanticLabel: l.back,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: PageContainer(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: VocaSpacing.xl),
                    children: [
                      Semantics(
                        header: true,
                        child: Text(l.settingsTitle, style: text.headline),
                      ),
                      const SizedBox(height: VocaSpacing.xl),

                      Text(l.settingsAppearance, style: text.subtitle),
                      const SizedBox(height: VocaSpacing.xxs),
                      Text(
                        l.settingsAppearanceHint,
                        style: text.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: VocaSpacing.md),

                      for (final option in _appearanceOptions(l)) ...[
                        SelectionCard(
                          title: option.title,
                          subtitle: option.subtitle,
                          selected: mode == option.mode,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .select(option.mode),
                        ),
                        const SizedBox(height: VocaSpacing.sm),
                      ],

                      const SizedBox(height: VocaSpacing.xl),
                      Text(l.settingsLanguage, style: text.subtitle),
                      const SizedBox(height: VocaSpacing.xxs),
                      Text(
                        l.settingsLanguageHint,
                        style: text.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: VocaSpacing.md),
                      // One row, not three cards. Appearance is a choice you compare;
                      // language is one you already know the answer to, so it only has to
                      // say what is set and open the list on demand.
                      _LanguageRow(
                        value: switch (locale.languageCode) {
                          'uz' => l.languageNameUz,
                          'ru' => l.languageNameRu,
                          _ => l.languageNameEn,
                        },
                        onTap: () => unawaited(showLanguageSheet(context)),
                      ),

                      const SizedBox(height: VocaSpacing.xl),
                      Text(l.settingsAccount, style: text.subtitle),
                      const SizedBox(height: VocaSpacing.md),
                      const SignOutButton(),
                      // Hidden for a guest: there is no mailbox to confirm from and
                      // nothing of theirs on the server to delete.
                      if (profile?.isGuest != true) ...[
                        const SizedBox(height: VocaSpacing.sm),
                        const _DeleteAccountRow(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The three appearance choices.
///
/// "System" is listed first and is the default: somebody whose phone switches at sunset
/// expects the app to switch with it, and that is the answer most people want without
/// knowing they want it.
class _Appearance {
  const _Appearance(this.mode, this.title, this.subtitle);

  final ThemeMode mode;
  final String title;
  final String subtitle;
}

List<_Appearance> _appearanceOptions(AppLocalizations l) => [
  _Appearance(ThemeMode.system, l.themeSystem, l.themeSystemHint),
  _Appearance(ThemeMode.light, l.themeLight, l.themeLightHint),
  _Appearance(ThemeMode.dark, l.themeDark, l.themeDarkHint),
];

/// The language row: what is set, and a way into the list.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;

    return PressScale(
      semanticLabel: '${context.l10n.settingsLanguage}: $value',
      onTap: onTap,
      child: ExcludeSemantics(
        child: GlassSurface(
          blur: false,
          padding: const EdgeInsets.all(VocaSpacing.md),
          borderRadius: BorderRadius.circular(VocaRadius.large),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Icon(
                  Icons.language_rounded,
                  size: 24,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: VocaSpacing.md),
                Expanded(
                  child: Text(
                    value,
                    style: text.body.copyWith(color: colors.textPrimary),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The way out that cannot be undone.
///
/// Marked by three things at once, so it never depends on colour alone: its own tint, an
/// icon, and wording that says what it destroys. It reads as dangerous in both themes and
/// to somebody who cannot tell the tint from the page.
class _DeleteAccountRow extends StatelessWidget {
  const _DeleteAccountRow();

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;

    return PressScale(
      semanticLabel: context.l10n.deleteAccount,
      onTap: () => unawaited(context.push(Routes.deleteAccount)),
      child: ExcludeSemantics(
        child: GlassSurface(
          edgeGlow: false,
          blur: false,
          showShadow: false,
          tint: colors.errorMuted,
          borderRadius: BorderRadius.circular(VocaRadius.large),
          padding: const EdgeInsets.all(VocaSpacing.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: colors.onErrorMuted,
                ),
                const SizedBox(width: VocaSpacing.md),
                Expanded(
                  child: Text(
                    context.l10n.deleteAccount,
                    style: text.body.copyWith(color: colors.onErrorMuted),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: colors.onErrorMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
