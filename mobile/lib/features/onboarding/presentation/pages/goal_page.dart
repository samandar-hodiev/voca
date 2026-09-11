/// Learning goal selection.
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

class GoalPage extends ConsumerWidget {
  const GoalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(setupProvider).goal;

    return SetupScaffold(
      title: context.l10n.goalTitle,
      subtitle: context.l10n.goalSubtitle,
      primaryLabel: context.l10n.continueAction,
      onPrimary: selected == null ? null : () => context.push(Routes.dailyGoal),
      child: Column(
        children: [
          for (final goal in learningGoals) ...[
            SelectionCard(
              title: context.l10n.learningGoalName(goal),
              selected: selected == goal,
              onTap: () => ref.read(setupProvider.notifier).setGoal(goal),
            ),
            const SizedBox(height: VocaSpacing.sm),
          ],
        ],
      ),
    );
  }
}
