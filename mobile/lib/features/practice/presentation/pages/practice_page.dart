/// Today's practice set.
///
/// A level filter, the words with how each is going, and one button to start. The list is
/// solid; the sheet a word opens into is glass, because that is what floats above the page.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/press_scale.dart';
import '../../../../core/widgets/progress_visuals.dart';
import '../../../../core/widgets/reveal.dart';
import '../../../../core/widgets/tab_scaffold.dart';
import '../../domain/entities/word.dart';
import '../controllers/practice_controller.dart';
import '../widgets/word_card.dart';
import '../widgets/word_practice_sheet.dart';

class PracticePage extends ConsumerWidget {
  const PracticePage({super.key});

  static const pageKey = ValueKey('practice-page');

  static const _levels = ['A1', 'A2', 'B1', 'B2', 'C1'];

  /// The first word still worth practising, so "start" never opens one already mastered.
  static Word _firstToPractise(List<Word> words) => words.firstWhere(
    (w) => w.status != PronunciationStatus.mastered,
    orElse: () => words.first,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final words = ref.watch(filteredPracticeSetProvider);
    final level = ref.watch(practiceLevelFilterProvider);

    void setLevel(String? l) =>
        ref.read(practiceLevelFilterProvider.notifier).state = l;

    return KeyedSubtree(
      key: pageKey,
      child: TabScaffold(
        title: 'Mashq',
        subtitle: 'Bugun uchun tanlangan so‘zlar',
        onRefresh: () async {
          ref.invalidate(dailyPracticeSetProvider);
          try {
            await ref.read(dailyPracticeSetProvider.future);
          } catch (_) {
            // The error state renders itself; the refresh gesture only has to end.
          }
        },
        children: [
          _LevelFilter(levels: _levels, selected: level, onChanged: setLevel),
          const SizedBox(height: VocaSpacing.lg),
          ...words.when(
            loading: () => [
              for (var i = 0; i < 4; i++) ...[
                SkeletonBox(
                  height: 96,
                  borderRadius: BorderRadius.circular(VocaRadius.large),
                ),
                const SizedBox(height: VocaSpacing.sm),
              ],
            ],
            error: (_, __) => [
              SizedBox(
                height: 320,
                child: ErrorView(
                  message: 'So‘zlarni yuklab bo‘lmadi.',
                  onRetry: () => ref.invalidate(dailyPracticeSetProvider),
                ),
              ),
            ],
            data: (list) => list.isEmpty
                ? [
                    SizedBox(
                      height: 280,
                      child: EmptyView(
                        title: 'Bu darajada so‘z yo‘q',
                        message: 'Boshqa darajani tanlang.',
                        icon: Icons.filter_alt_off_outlined,
                        actionLabel: 'Barchasini ko‘rsatish',
                        onAction: () => setLevel(null),
                      ),
                    ),
                  ]
                : [
                    Reveal(index: 0, child: _SetSummary(words: list)),
                    const SizedBox(height: VocaSpacing.md),
                    for (var i = 0; i < list.length; i++) ...[
                      Reveal(
                        index: 1 + i,
                        child: WordCard(
                          word: list[i],
                          onTap: () => showWordPracticeSheet(context, list[i]),
                        ),
                      ),
                      const SizedBox(height: VocaSpacing.sm),
                    ],
                    const SizedBox(height: VocaSpacing.md),
                    PrimaryButton(
                      label: 'Mashqni boshlash',
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => showWordPracticeSheet(
                        context,
                        _firstToPractise(list),
                      ),
                    ),
                  ],
          ),
        ],
      ),
    );
  }
}

/// How far through the set the learner is.
class _SetSummary extends StatelessWidget {
  const _SetSummary({required this.words});

  final List<Word> words;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    final done = words
        .where(
          (w) =>
              w.status == PronunciationStatus.good ||
              w.status == PronunciationStatus.mastered,
        )
        .length;

    return Semantics(
      label: '${words.length} ta so‘z, $done tasi yaxshi yoki o‘zlashtirilgan',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(VocaSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(VocaRadius.large),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: colors.primary,
                ),
                const SizedBox(width: VocaSpacing.xs),
                Expanded(
                  child: Text(
                    '${words.length} ta so‘z · $done tasi yaxshi',
                    style: text.subtitle.copyWith(color: colors.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: VocaSpacing.sm),
            AnimatedProgressBar(value: words.isEmpty ? 0 : done / words.length),
          ],
        ),
      ),
    );
  }
}

/// All levels or one. Selection is shown with a check as well as a fill, never by colour
/// alone.
class _LevelFilter extends StatelessWidget {
  const _LevelFilter({
    required this.levels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> levels;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: VocaSpacing.xs,
      runSpacing: VocaSpacing.xs,
      children: [
        _Pill(
          label: 'Barchasi',
          selected: selected == null,
          onTap: () => onChanged(null),
        ),
        for (final l in levels)
          _Pill(label: l, selected: selected == l, onTap: () => onChanged(l)),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;

    return Semantics(
      selected: selected,
      child: PressScale(
        semanticLabel: '$label darajasi',
        onTap: onTap,
        child: AnimatedContainer(
          duration: VocaMotion.respectReducedMotion(context, VocaMotion.quick),
          curve: VocaMotion.standardCurve,
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: VocaSpacing.md),
          decoration: BoxDecoration(
            color: selected ? colors.primary : colors.surface,
            borderRadius: BorderRadius.circular(VocaRadius.pill),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: 16, color: colors.onPrimary),
                const SizedBox(width: VocaSpacing.xxs),
              ],
              Text(
                label,
                style: text.label.copyWith(
                  color: selected ? colors.onPrimary : colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
