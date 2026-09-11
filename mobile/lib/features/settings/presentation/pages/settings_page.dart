/// Account settings.
///
/// The first thing here is appearance, because it is the one setting that changes what
/// every other screen looks like. Language, accent, difficulty and reminders follow as
/// their features arrive.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/widgets/sign_out_button.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/locale_controller.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/liquid_background.dart';
import '../../../../core/widgets/selection_card.dart';
import '../../../../l10n/l10n.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    final mode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final l = context.l10n;

    return Scaffold(
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
                      // Each language is named in itself, so anyone can find their own.
                      for (final (code, name) in [
                        ('en', l.languageNameEn),
                        ('uz', l.languageNameUz),
                        ('ru', l.languageNameRu),
                      ]) ...[
                        SelectionCard(
                          title: name,
                          selected: locale.languageCode == code,
                          onTap: () =>
                              ref.read(localeProvider.notifier).select(code),
                        ),
                        const SizedBox(height: VocaSpacing.sm),
                      ],

                      const SizedBox(height: VocaSpacing.xl),
                      Text(l.settingsAccount, style: text.subtitle),
                      const SizedBox(height: VocaSpacing.md),
                      const SignOutButton(),
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
