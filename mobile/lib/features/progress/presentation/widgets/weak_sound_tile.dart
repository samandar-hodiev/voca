/// A sound the learner keeps getting wrong, with how often and an example word.
///
/// The accuracy is written as a number as well as drawn as a bar, and the bar's colour is
/// only a second cue. The example word is there because most learners cannot read IPA.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/progress_visuals.dart';
import '../../../../core/widgets/sound_symbol.dart';
import '../../domain/entities/weak_sound.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../l10n/l10n.dart';

class WeakSoundTile extends StatelessWidget {
  const WeakSoundTile({super.key, required this.sound});

  final WeakSound sound;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    final tone = sound.accuracy < 60
        ? colors.error
        : sound.accuracy < 75
        ? colors.warning
        : colors.success;

    return Semantics(
      label: context.l10n.weakSoundSemantic(
        sound.symbol,
        sound.example,
        sound.accuracy,
      ),
      excludeSemantics: true,
      child: GlassSurface(
        blur: false,
        padding: const EdgeInsets.all(VocaSpacing.md),
        borderRadius: BorderRadius.circular(VocaRadius.large),
        child: Row(
          children: [
            SoundSymbol(symbol: sound.symbol),
            const SizedBox(width: VocaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.forExample(sound.example),
                          style: text.subtitle.copyWith(
                            color: colors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${sound.accuracy}%',
                        style: text.label.copyWith(color: colors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: VocaSpacing.xs),
                  AnimatedProgressBar(value: sound.accuracy / 100, color: tone),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
