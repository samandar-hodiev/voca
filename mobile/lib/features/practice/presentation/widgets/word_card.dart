/// A word in the practice list, with its level and how it is going.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/press_scale.dart';
import '../../../../core/widgets/sound_symbol.dart';
import '../../domain/entities/word.dart';
import '../../../../core/widgets/glass_surface.dart';

/// How each status is shown. A label and an icon for every state, so none of them rely on
/// colour to be told apart.
extension PronunciationStatusUi on PronunciationStatus {
  String get label => switch (this) {
    PronunciationStatus.notStarted => 'Boshlanmagan',
    PronunciationStatus.needsWork => 'Mashq kerak',
    PronunciationStatus.good => 'Yaxshi',
    PronunciationStatus.mastered => 'O‘zlashtirilgan',
  };

  BadgeTone get tone => switch (this) {
    PronunciationStatus.notStarted => BadgeTone.neutral,
    PronunciationStatus.needsWork => BadgeTone.warning,
    PronunciationStatus.good => BadgeTone.primary,
    PronunciationStatus.mastered => BadgeTone.success,
  };

  IconData get icon => switch (this) {
    PronunciationStatus.notStarted => Icons.radio_button_unchecked_rounded,
    PronunciationStatus.needsWork => Icons.error_outline_rounded,
    PronunciationStatus.good => Icons.check_circle_outline_rounded,
    PronunciationStatus.mastered => Icons.verified_rounded,
  };
}

class WordCard extends StatelessWidget {
  const WordCard({super.key, required this.word, this.onTap});

  final Word word;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    final score = word.bestScore;

    return PressScale(
      semanticLabel:
          '${word.text}, ${word.level} daraja, ${word.status.label}'
          '${score == null ? '' : ', eng yaxshi natija $score'}. Mashq qilish',
      onTap: onTap,
      child: ExcludeSemantics(
        child: GlassSurface(
          blur: false,
          padding: const EdgeInsets.all(VocaSpacing.md),
          borderRadius: BorderRadius.circular(VocaRadius.large),
          child: Row(
            children: [
              SoundSymbol(symbol: word.focusSound),
              const SizedBox(width: VocaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            word.text,
                            style: text.subtitle.copyWith(
                              color: colors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: VocaSpacing.xs),
                        AppBadge(label: word.level),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${word.ipa} · ${word.meaningUz}',
                      style: text.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: VocaSpacing.xs),
                    AppBadge(
                      label: score == null
                          ? word.status.label
                          : '${word.status.label} · $score',
                      tone: word.status.tone,
                      icon: word.status.icon,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
