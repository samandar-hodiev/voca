/// Account settings.
///
/// The first thing here is appearance, because it is the one setting that changes what
/// every other screen looks like. Language, accent, difficulty and reminders follow as
/// their features arrive.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/liquid_background.dart';
import '../../../../core/widgets/selection_card.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    final mode = ref.watch(themeModeProvider);

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
                          semanticLabel: 'Orqaga',
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
                        child: Text('Sozlamalar', style: text.headline),
                      ),
                      const SizedBox(height: VocaSpacing.xl),

                      Text('Ko‘rinish', style: text.subtitle),
                      const SizedBox(height: VocaSpacing.xxs),
                      Text(
                        'Ilova qanday ko‘rinishini tanlang.',
                        style: text.caption.copyWith(color: colors.textSecondary),
                      ),
                      const SizedBox(height: VocaSpacing.md),

                      for (final option in _appearanceOptions) ...[
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
/// "Tizim bo‘yicha" is listed first and is the default: somebody whose phone switches at
/// sunset expects the app to switch with it, and that is the answer most people want
/// without knowing they want it.
class _Appearance {
  const _Appearance(this.mode, this.title, this.subtitle);

  final ThemeMode mode;
  final String title;
  final String subtitle;
}

const _appearanceOptions = [
  _Appearance(
    ThemeMode.system,
    'Tizim bo‘yicha',
    'Telefon sozlamasiga ergashadi',
  ),
  _Appearance(
    ThemeMode.light,
    'Yorug‘',
    'Doim yorug‘ ko‘rinish',
  ),
  _Appearance(
    ThemeMode.dark,
    'Qorong‘i',
    'Doim qorong‘i ko‘rinish',
  ),
];
