/// How the learner is doing: overall score, the week, weak sounds and recent attempts.
///
/// Solid cards throughout. This page is read, not acted on, and a stack of glass panes
/// would compete with the numbers it exists to show.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/progress_visuals.dart';
import '../../../../core/widgets/reveal.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/widgets/tab_scaffold.dart';
import '../../domain/entities/progress_summary.dart';
import '../controllers/progress_controller.dart';
import '../widgets/progress_chart.dart';
import '../widgets/weak_sound_tile.dart';

class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  static const pageKey = ValueKey('progress-page');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(progressSummaryProvider);

    return KeyedSubtree(
      key: pageKey,
      child: TabScaffold(
        title: 'Natijalar',
        subtitle: 'So‘nggi 7 kun',
        onRefresh: () async {
          ref.invalidate(progressSummaryProvider);
          try {
            await ref.read(progressSummaryProvider.future);
          } catch (_) {
            // The error state renders itself; the refresh gesture only has to end.
          }
        },
        children: summary.when(
          loading: () => [
            SkeletonBox(
              height: 150,
              borderRadius: BorderRadius.circular(VocaRadius.xlarge),
            ),
            const SizedBox(height: VocaSpacing.md),
            SkeletonBox(
              height: 110,
              borderRadius: BorderRadius.circular(VocaRadius.large),
            ),
            const SizedBox(height: VocaSpacing.md),
            SkeletonBox(
              height: 200,
              borderRadius: BorderRadius.circular(VocaRadius.large),
            ),
          ],
          error: (_, __) => [
            SizedBox(
              height: 320,
              child: ErrorView(
                message: 'Natijalarni yuklab bo‘lmadi.',
                onRetry: () => ref.invalidate(progressSummaryProvider),
              ),
            ),
          ],
          data: (s) => [
            Reveal(index: 0, child: _ScoreHero(summary: s)),
            const SizedBox(height: VocaSpacing.md),
            Reveal(index: 1, child: _Stats(summary: s)),
            const SizedBox(height: VocaSpacing.xl),
            const Reveal(
              index: 2,
              child: SectionHeader(
                title: 'Haftalik faollik',
                subtitle: 'Kunlik maqsadga nisbatan',
              ),
            ),
            Reveal(index: 2, child: WeeklyActivityChart(days: s.week)),
            const SizedBox(height: VocaSpacing.xl),
            const Reveal(
              index: 3,
              child: SectionHeader(
                title: 'Zaif tovushlar',
                subtitle: 'Aniqlik bo‘yicha',
              ),
            ),
            for (var i = 0; i < s.weakSounds.length; i++) ...[
              Reveal(
                index: 4 + i,
                child: WeakSoundTile(sound: s.weakSounds[i]),
              ),
              const SizedBox(height: VocaSpacing.sm),
            ],
            const SizedBox(height: VocaSpacing.lg),
            const Reveal(
              index: 6,
              child: SectionHeader(title: 'So‘nggi mashqlar'),
            ),
            Reveal(index: 6, child: _RecentList(records: s.recent)),
          ],
        ),
      ),
    );
  }
}

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    final s = summary;
    final up = s.scoreDelta >= 0;

    final ring = Semantics(
      label: 'O‘rtacha talaffuz balli ${s.overallScore} / 100',
      excludeSemantics: true,
      child: ProgressRing(
        value: s.overallScore / 100,
        size: 104,
        stroke: 10,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${s.overallScore}',
              style: text.headline.copyWith(color: colors.textPrimary),
            ),
            Text(
              '/100',
              style: text.caption.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'O‘rtacha talaffuz balli',
          style: text.subtitle.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: VocaSpacing.xs),
        // The direction is carried by the sign and the icon, not only by the colour.
        AppBadge(
          label: '${up ? '+' : ''}${s.scoreDelta} ball',
          tone: up ? BadgeTone.success : BadgeTone.error,
          icon: up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
        ),
        const SizedBox(height: VocaSpacing.xs),
        Text(
          'O‘tgan haftaga nisbatan',
          style: text.caption.copyWith(color: colors.textSecondary),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(VocaSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(VocaRadius.xlarge),
        border: Border.all(color: colors.border),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          if (box.maxWidth < 300) {
            return Column(
              children: [
                ring,
                const SizedBox(height: VocaSpacing.md),
                copy,
              ],
            );
          }
          return Row(
            children: [
              ring,
              const SizedBox(width: VocaSpacing.lg),
              Expanded(child: copy),
            ],
          );
        },
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final s = summary;

    return StatPair(
      left: StatCard(
        label: 'Mashq qilingan so‘zlar',
        value: '${s.wordsPracticed}',
        icon: Icons.menu_book_rounded,
        caption: 'Jami',
      ),
      right: StatCard(
        label: 'Seriya',
        value: '${s.streakDays} kun',
        icon: Icons.local_fire_department_rounded,
        accent: colors.warning,
        caption: 'Eng yaxshisi: ${s.bestStreak} kun',
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({required this.records});

  final List<PracticeRecord> records;

  static String _when(DateTime at, DateTime now) {
    final days = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(at.year, at.month, at.day)).inDays;
    if (days <= 0) return 'Bugun';
    if (days == 1) return 'Kecha';
    return '$days kun oldin';
  }

  static BadgeTone _tone(int score) {
    if (score >= 85) return BadgeTone.success;
    if (score >= 65) return BadgeTone.primary;
    return BadgeTone.warning;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    final now = DateTime.now();

    if (records.isEmpty) {
      return Text(
        'Hali mashq qilinmagan.',
        style: text.body.copyWith(color: colors.textSecondary),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VocaRadius.large),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < records.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: colors.border),
            Semantics(
              label:
                  '${records[i].word}, ${_when(records[i].at, now)}, '
                  '${records[i].score} ball',
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VocaSpacing.md,
                  vertical: VocaSpacing.sm + 2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            records[i].word,
                            style: text.subtitle.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            _when(records[i].at, now),
                            style: text.caption.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppBadge(
                      label: '${records[i].score}',
                      tone: _tone(records[i].score),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
