/// English level selection.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/selection_card.dart';
import '../../../../core/widgets/setup_scaffold.dart';
import '../../../../routing/routes.dart';
import '../controllers/setup_controller.dart';

class LevelPage extends ConsumerWidget {
  const LevelPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(setupProvider).level;

    return SetupScaffold(
      title: 'Ingliz tilini qay darajada bilasiz?',
      subtitle: 'Mashqlar shu darajaga moslashtiriladi.',
      primaryLabel: 'Davom etish',
      // Disabled until something is chosen: an action that cannot succeed should not
      // look available.
      onPrimary: selected == null ? null : () => context.push(Routes.goal),
      child: Column(
        children: [
          for (final level in cefrLevels) ...[
            SelectionCard(
              leading: level.code,
              title: level.label,
              subtitle: level.description,
              selected: selected == level.code,
              onTap: () => ref.read(setupProvider.notifier).setLevel(level.code),
            ),
            const SizedBox(height: VocaSpacing.sm),
          ],
        ],
      ),
    );
  }
}
