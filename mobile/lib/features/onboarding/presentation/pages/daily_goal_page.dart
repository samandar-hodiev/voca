/// Daily practice goal.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/selection_card.dart';
import '../../../../core/widgets/setup_scaffold.dart';
import '../../../../routing/routes.dart';
import '../controllers/setup_controller.dart';
import '../../../../l10n/l10n.dart';

class DailyGoalPage extends ConsumerWidget {
  const DailyGoalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pre-selected rather than blank. Ten is a good answer for most people, and an
    // already-valid screen is faster to pass through than an empty one.
    final selected =
        ref.watch(setupProvider).dailyGoalWords ?? recommendedDailyGoal;

    return SetupScaffold(
      title: context.l10n.dailyGoalTitle,
      subtitle: context.l10n.dailyGoalSubtitle,
      primaryLabel: context.l10n.continueAction,
      onPrimary: () {
        ref.read(setupProvider.notifier).setDailyGoal(selected);
        context.push(Routes.authEntry);
      },
      child: Column(
        children: [
          for (final words in dailyGoalOptions) ...[
            SelectionCard(
              title: context.l10n.wordsCount(words),
              subtitle: _estimate(context.l10n, words),
              badge: words == recommendedDailyGoal
                  ? context.l10n.recommended
                  : null,
              selected: selected == words,
              onTap: () => ref.read(setupProvider.notifier).setDailyGoal(words),
            ),
            const SizedBox(height: VocaSpacing.sm),
          ],
        ],
      ),
    );
  }

  /// A rough time estimate, so the number means something.
  String _estimate(AppLocalizations l, int words) =>
      l.aboutMinutes(switch (words) {
        5 => 3,
        10 => 5,
        15 => 8,
        _ => 10,
      });
}
