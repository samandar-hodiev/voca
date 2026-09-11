/// The sheet a word opens into: the word itself, and where recording will happen.
///
/// Recording and scoring are the pronunciation assessment feature, which is not built yet.
/// The control is shown, disabled, and says so. A button that does nothing when tapped is
/// worse than one that is honestly unavailable.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/sound_symbol.dart';
import '../../domain/entities/practice_item.dart';
import '../../domain/entities/word.dart';

Future<void> showWordPracticeSheet(BuildContext context, Word word) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _WordPracticeSheet(attempt: PracticeAttempt(word: word)),
  );
}

class _WordPracticeSheet extends StatelessWidget {
  const _WordPracticeSheet({required this.attempt});

  final PracticeAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    final word = attempt.word;

    return Padding(
      padding: const EdgeInsets.all(VocaSpacing.md),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(
          VocaSpacing.xl,
          VocaSpacing.md,
          VocaSpacing.xl,
          VocaSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: VocaSpacing.lg),
            SoundSymbol(symbol: word.focusSound, size: 56),
            const SizedBox(height: VocaSpacing.md),
            Semantics(
              header: true,
              child: Text(
                word.text,
                style: text.display.copyWith(color: colors.textPrimary),
                textAlign: TextAlign.center,
              ),
            ),
            Text(
              word.ipa,
              style: text.title.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: VocaSpacing.xs),
            Text(
              word.meaningUz,
              style: text.body.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: VocaSpacing.xl),
            Semantics(
              button: true,
              enabled: false,
              label: 'Ovozni yozib olish, hozircha mavjud emas',
              child: ExcludeSemantics(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary.withValues(alpha: 0.32),
                  ),
                  child: Icon(
                    Icons.mic_rounded,
                    size: 36,
                    color: colors.onPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: VocaSpacing.sm),
            Text(
              'Talaffuzni baholash keyingi bosqichda ulanadi.',
              style: text.caption.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VocaSpacing.lg),
            SecondaryButton(
              label: 'Yopish',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
