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

class GoalPage extends ConsumerWidget {
  const GoalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(setupProvider).goal;

    return SetupScaffold(
      title: 'Nima uchun ingliz tilini o‘rganyapsiz?',
      subtitle: 'Bu tavsiyalarni shakllantiradi.',
      primaryLabel: 'Davom etish',
      onPrimary: selected == null ? null : () => context.push(Routes.dailyGoal),
      child: Column(
        children: [
          for (final goal in learningGoals) ...[
            SelectionCard(
              title: goal.label,
              selected: selected == goal.id,
              onTap: () => ref.read(setupProvider.notifier).setGoal(goal.id),
            ),
            const SizedBox(height: VocaSpacing.sm),
          ],
        ],
      ),
    );
  }
}
