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
import '../../../../l10n/l10n.dart';

/// How each status is shown. A label and an icon for every state, so none of them rely on
/// colour to be told apart.
extension PronunciationStatusUi on PronunciationStatus {
  String label(AppLocalizations l) => switch (this) {
    PronunciationStatus.notStarted => l.statusNotStarted,
    PronunciationStatus.needsWork => l.statusNeedsWork,
    PronunciationStatus.good => l.statusGood,
    PronunciationStatus.mastered => l.statusMastered,
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
          '${context.l10n.wordCardSemantic(word.text, word.level, word.status.label(context.l10n))}'
          '${score == null ? '' : context.l10n.bestScoreSemantic(score)}. ${context.l10n.practiseAction}',
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
                            style: text.title.copyWith(
                              color: colors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: VocaSpacing.xs),
                        AppBadge(label: word.level),
                      ],
                    ),
                    const SizedBox(height: VocaSpacing.xxs),
                    Text(
                      // The meanings on hand are Uzbek, so they are shown with the Uzbek
                      // interface only; the other languages show the sounds.
                      Localizations.localeOf(context).languageCode == 'uz'
                          ? '${word.ipa} · ${word.meaningUz}'
                          : word.ipa,
                      style: text.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: VocaSpacing.xs),
                    AppBadge(
                      label: score == null
                          ? word.status.label(context.l10n)
                          : '${word.status.label(context.l10n)} · $score',
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
