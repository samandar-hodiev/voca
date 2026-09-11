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
import '../../../../l10n/l10n.dart';

class LevelPage extends ConsumerWidget {
  const LevelPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(setupProvider).level;

    return SetupScaffold(
      title: context.l10n.levelTitle,
      subtitle: context.l10n.levelSubtitle,
      primaryLabel: context.l10n.continueAction,
      // Disabled until something is chosen: an action that cannot succeed should not
      // look available.
      onPrimary: selected == null ? null : () => context.push(Routes.goal),
      child: Column(
        children: [
          for (final level in cefrLevels) ...[
            SelectionCard(
              leading: level,
              title: context.l10n.cefrLevelName(level),
              subtitle: context.l10n.cefrLevelHint(level),
              selected: selected == level,
              onTap: () => ref.read(setupProvider.notifier).setLevel(level),
            ),
            const SizedBox(height: VocaSpacing.sm),
          ],
        ],
      ),
    );
  }
}
