/// Choosing how the app looks.
///
/// The same shape as the language picker: one row on Settings says what is set, and the
/// list itself lives behind a tap. Three cards laid out permanently gave a setting most
/// people touch once the same weight as the things they come to Settings for.
///
/// Each mode carries an icon, because "System", "Light" and "Dark" are quicker to tell
/// apart by symbol than by reading three short words.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/theme_mode_controller.dart';
import 'glass_surface.dart';
import 'selection_card.dart';

/// The three appearance choices, in the order they are offered.
///
/// "System" comes first and is the default: somebody whose phone switches at sunset
/// expects the app to switch with it, and that is the answer most people want without
/// knowing they want it.
const appearanceChoices = [
  (ThemeMode.system, Icons.brightness_auto_rounded),
  (ThemeMode.light, Icons.light_mode_rounded),
  (ThemeMode.dark, Icons.dark_mode_rounded),
];

/// The name of a mode in the current language.
String appearanceName(AppLocalizations l, ThemeMode mode) => switch (mode) {
  ThemeMode.system => l.themeSystem,
  ThemeMode.light => l.themeLight,
  ThemeMode.dark => l.themeDark,
};

String _appearanceHint(AppLocalizations l, ThemeMode mode) => switch (mode) {
  ThemeMode.system => l.themeSystemHint,
  ThemeMode.light => l.themeLightHint,
  ThemeMode.dark => l.themeDarkHint,
};

/// The icon for a mode, so the Settings row and the sheet always agree.
IconData appearanceIcon(ThemeMode mode) =>
    appearanceChoices.firstWhere((c) => c.$1 == mode).$2;

/// Opens the appearance picker.
Future<void> showAppearanceSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(VocaSpacing.md),
        child: GlassCard(
          // Scrolls rather than overflows: three options with their hints are taller
          // than a short screen leaves a bottom sheet, and a sheet that overflows shows
          // a striped bar instead of the last choice.
          child: SingleChildScrollView(
            child: Consumer(
              builder: (context, ref, _) {
                final current = ref.watch(themeModeProvider);
                final l = context.l10n;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l.appearanceSelectTitle,
                      style: context.vocaText.title,
                    ),
                    const SizedBox(height: VocaSpacing.md),
                    for (final (mode, icon) in appearanceChoices) ...[
                      SelectionCard(
                        icon: icon,
                        title: appearanceName(l, mode),
                        subtitle: _appearanceHint(l, mode),
                        selected: current == mode,
                        onTap: () {
                          // The theme changes under the sheet before it closes, so the
                          // choice is visible the moment it is made.
                          unawaited(
                            ref.read(themeModeProvider.notifier).select(mode),
                          );
                          Navigator.of(sheet).pop();
                        },
                      ),
                      const SizedBox(height: VocaSpacing.sm),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}
