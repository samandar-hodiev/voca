/// A small glass button that shows the current language and lets it be changed.
///
/// It sits on the very first screen, so somebody who does not read English can switch
/// before they have to read anything else. Settings offers the same choice later.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../l10n/locale_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'glass_surface.dart';
import 'liquid_drop.dart';
import 'press_scale.dart';
import 'selection_card.dart';

class LanguageButton extends ConsumerWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    final code = ref.watch(localeProvider).languageCode;

    return PressScale(
      semanticLabel: context.l10n.settingsLanguage,
      onTap: () => unawaited(_choose(context)),
      child: GlassBead(
        padding: const EdgeInsets.symmetric(
          horizontal: VocaSpacing.sm,
          vertical: VocaSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language_rounded, size: 18, color: colors.textPrimary),
            const SizedBox(width: VocaSpacing.xxs),
            Text(
              code.toUpperCase(),
              style: text.label.copyWith(color: colors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _choose(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(VocaSpacing.md),
          child: GlassCard(
            child: Consumer(
              builder: (context, ref, _) {
                final current = ref.watch(localeProvider).languageCode;
                final l = context.l10n;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.settingsLanguage, style: context.vocaText.title),
                    const SizedBox(height: VocaSpacing.md),
                    // Each language is named in itself, so anyone can find their own.
                    for (final (code, name) in [
                      ('en', l.languageNameEn),
                      ('uz', l.languageNameUz),
                      ('ru', l.languageNameRu),
                    ]) ...[
                      SelectionCard(
                        title: name,
                        selected: current == code,
                        onTap: () {
                          unawaited(
                            ref.read(localeProvider.notifier).select(code),
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
    );
  }
}
