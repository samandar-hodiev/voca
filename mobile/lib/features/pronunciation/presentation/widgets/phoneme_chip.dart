/// One sound and how it scored.
///
/// Small enough to sit several to a row under a word, because the useful unit of practice
/// is "your θ needs work", not "that word was 58".
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/l10n.dart';
import 'score_palette.dart';

class PhonemeChip extends StatelessWidget {
  const PhonemeChip({super.key, required this.phoneme, required this.accuracy});

  final String phoneme;
  final double accuracy;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    final band = bandFor(accuracy);
    final rounded = accuracy.round();

    return Semantics(
      label: '${context.l10n.soundSemantic(phoneme)}: $rounded',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VocaSpacing.sm,
          vertical: VocaSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: bandFill(colors, band),
          borderRadius: VocaRadius.pillAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '/$phoneme/',
              style: text.label.copyWith(
                color: bandOnFill(colors, band),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: VocaSpacing.xxs),
            Text(
              '$rounded',
              style: text.caption.copyWith(color: bandOnFill(colors, band)),
            ),
          ],
        ),
      ),
    );
  }
}
