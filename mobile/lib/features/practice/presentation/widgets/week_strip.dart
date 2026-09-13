/// The week, with one day open and the rest locked.
///
/// The plan is deliberately visible: seeing six locked days is what makes finishing today
/// mean something. What is not offered is a way round them — the lock is decided by the
/// server, and this widget only draws the answer.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/entities/practice_session.dart';

class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key, required this.days});

  final List<PracticeDay> days;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: VocaSpacing.xs),
        itemBuilder: (context, i) => _DayTile(day: days[i], index: i),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.day, required this.index});

  final PracticeDay day;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    final l10n = context.l10n;

    // Status is never carried by colour alone: each state has its own icon, and the
    // locked ones are also dimmed and unlabelled.
    final (icon, fill, ink) = switch (day.status) {
      PracticeDayStatus.passed => (
        Icons.check_rounded,
        colors.successMuted,
        colors.onSuccessMuted,
      ),
      PracticeDayStatus.failed => (
        Icons.replay_rounded,
        colors.warningMuted,
        colors.onWarningMuted,
      ),
      PracticeDayStatus.inProgress => (
        Icons.play_arrow_rounded,
        colors.primaryMuted,
        colors.onPrimaryMuted,
      ),
      PracticeDayStatus.available => (
        Icons.play_arrow_rounded,
        colors.primaryMuted,
        colors.onPrimaryMuted,
      ),
      PracticeDayStatus.locked => (
        Icons.lock_outline_rounded,
        colors.surface,
        colors.textDisabled,
      ),
    };

    return Semantics(
      label: l10n.dayNumber(index + 1),
      enabled: day.unlocked,
      child: Container(
        width: 62,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(VocaRadius.element),
          border: Border.all(
            color: day.unlocked ? colors.primary : colors.border,
            width: day.unlocked ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: ink),
            const SizedBox(height: VocaSpacing.xxs),
            Text(
              l10n.dayNumber(index + 1),
              style: text.caption.copyWith(color: ink),
            ),
            if (day.averageScore != null)
              Text(
                '${day.averageScore!.round()}',
                style: text.caption.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
