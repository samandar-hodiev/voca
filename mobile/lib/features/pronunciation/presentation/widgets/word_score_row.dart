/// One word of the attempt: what it scored, and which of its sounds let it down.
///
/// Shown for every word so a learner can see that the sentence was fine apart from one
/// place, rather than being handed a single number for the whole utterance.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/word_result.dart';
import 'phoneme_chip.dart';
import 'score_palette.dart';

class WordScoreRow extends StatelessWidget {
  const WordScoreRow({super.key, required this.result});

  final WordResult result;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    final band = bandFor(result.accuracy);

    // Only the sounds that need work. Listing every phoneme of a word scored 98 buries
    // the one chip that matters on the words that did not.
    final weak = result.phonemes.where((p) => p.accuracy < 60).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VocaSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  result.word,
                  style: text.subtitle.copyWith(color: colors.textPrimary),
                ),
              ),
              Text(
                '${result.accuracy.round()}',
                style: text.subtitle.copyWith(
                  color: bandColor(colors, band),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (weak.isNotEmpty) ...[
            const SizedBox(height: VocaSpacing.xxs),
            Wrap(
              spacing: VocaSpacing.xs,
              runSpacing: VocaSpacing.xxs,
              children: [
                for (final p in weak)
                  PhonemeChip(phoneme: p.phoneme, accuracy: p.accuracy),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
