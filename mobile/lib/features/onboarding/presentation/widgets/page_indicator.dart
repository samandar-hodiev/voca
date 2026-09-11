/// Progress dots for a paged flow.
///
/// The active dot widens rather than only changing colour, so position is readable
/// without relying on colour perception.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/liquid_drop.dart';
import '../../../../l10n/l10n.dart';

class PageIndicator extends StatelessWidget {
  const PageIndicator({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    return Semantics(
      label: context.l10n.pageOf(index + 1, count),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final active = i == index;
          return AnimatedContainer(
            duration: VocaMotion.respectReducedMotion(
              context,
              VocaMotion.quick,
            ),
            curve: VocaMotion.standardCurve,
            margin: const EdgeInsets.symmetric(horizontal: VocaSpacing.xxs),
            height: 8,
            width: active ? 26 : 8,
            child: active
                ? const LiquidDrop(glow: false)
                : GlassBead(tint: colors.borderStrong.withValues(alpha: 0.6)),
          );
        }),
      ),
    );
  }
}
