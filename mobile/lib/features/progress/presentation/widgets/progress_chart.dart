/// The week as seven bars, one per day, against the daily goal.
///
/// Drawn from plain widgets rather than a chart library: seven bars do not justify a
/// dependency. A day that met its goal carries a check mark as well as a stronger fill, so
/// the chart still reads for somebody who cannot tell the two fills apart.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/daily_progress.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/liquid_drop.dart';
import '../../../../l10n/l10n.dart';

class WeeklyActivityChart extends StatelessWidget {
  const WeeklyActivityChart({super.key, required this.days});

  /// Oldest first.
  final List<DailyProgress> days;

  static String _name(AppLocalizations l, DateTime d) =>
      l.weekdayShort('${d.weekday}');

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    if (days.isEmpty) return const SizedBox.shrink();

    final peak = days.fold<int>(
      1,
      (m, d) => math.max(m, math.max(d.words, d.goal)),
    );
    final today = DateTime.now();
    final spoken = days
        .map(
          (d) =>
              '${_name(context.l10n, d.day)}: ${context.l10n.wordsCount(d.words)}${d.goalMet ? context.l10n.goalMetSuffix : ''}',
        )
        .join('; ');

    return Semantics(
      label: '${context.l10n.weeklyActivity}. $spoken',
      excludeSemantics: true,
      child: GlassSurface(
        blur: false,
        padding: const EdgeInsets.fromLTRB(
          VocaSpacing.md,
          VocaSpacing.lg,
          VocaSpacing.md,
          VocaSpacing.md,
        ),
        borderRadius: BorderRadius.circular(VocaRadius.large),
        child: Column(
          children: [
            SizedBox(
              height: 132,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final d in days)
                    Expanded(
                      child: _Bar(
                        ratio: d.words / peak,
                        goalMet: d.goalMet,
                        words: d.words,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: VocaSpacing.xs),
            Row(
              children: [
                for (final d in days)
                  Expanded(
                    child: Text(
                      _name(context.l10n, d.day),
                      textAlign: TextAlign.center,
                      style: text.caption.copyWith(
                        color: _sameDay(d.day, today)
                            ? colors.textPrimary
                            : colors.textSecondary,
                        fontWeight: _sameDay(d.day, today)
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: VocaSpacing.md),
            Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: colors.success,
                ),
                const SizedBox(width: VocaSpacing.xxs),
                Text(
                  context.l10n.dailyGoalMet,
                  style: text.caption.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.ratio, required this.goalMet, required this.words});

  final double ratio;
  final bool goalMet;
  final int words;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$words',
          style: text.caption.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: TweenAnimationBuilder<double>(
              // A sliver of bar even on a zero day, so every day has a visible place.
              tween: Tween(begin: 0, end: ratio.clamp(0.04, 1.0)),
              duration: VocaMotion.respectReducedMotion(
                context,
                VocaMotion.emphasized,
              ),
              curve: VocaMotion.enterCurve,
              builder: (context, v, _) => FractionallySizedBox(
                heightFactor: v,
                child: SizedBox(
                  width: 18,
                  child: LiquidDrop(
                    color: goalMet
                        ? colors.primary
                        : Color.lerp(colors.primary, colors.surface, 0.55),
                    borderRadius: BorderRadius.circular(VocaRadius.small),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 16,
          child: goalMet
              ? Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: colors.success,
                )
              : null,
        ),
      ],
    );
  }
}
