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

class DailyGoalPage extends ConsumerWidget {
  const DailyGoalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pre-selected rather than blank. Ten is a good answer for most people, and an
    // already-valid screen is faster to pass through than an empty one.
    final selected = ref.watch(setupProvider).dailyGoalWords ?? recommendedDailyGoal;

    return SetupScaffold(
      title: 'Kuniga qancha mashq qilasiz?',
      subtitle: 'Buni keyin sozlamalardan o‘zgartirishingiz mumkin.',
      primaryLabel: 'Davom etish',
      onPrimary: () {
        ref.read(setupProvider.notifier).setDailyGoal(selected);
        context.push(Routes.authEntry);
      },
      child: Column(
        children: [
          for (final words in dailyGoalOptions) ...[
            SelectionCard(
              title: '$words ta so‘z',
              subtitle: _estimate(words),
              badge: words == recommendedDailyGoal ? 'Tavsiya etiladi' : null,
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
  String _estimate(int words) => switch (words) {
        5 => 'Taxminan 3 daqiqa',
        10 => 'Taxminan 5 daqiqa',
        15 => 'Taxminan 8 daqiqa',
        _ => 'Taxminan 10 daqiqa',
      };
}
