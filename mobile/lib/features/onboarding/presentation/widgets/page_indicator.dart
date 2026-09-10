/// Progress dots for a paged flow.
///
/// The active dot widens rather than only changing colour, so position is readable
/// without relying on colour perception.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class PageIndicator extends StatelessWidget {
  const PageIndicator({
    super.key,
    required this.count,
    required this.index,
  });

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    return Semantics(
      label: 'Sahifa ${index + 1} / $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final active = i == index;
          return AnimatedContainer(
            duration: VocaMotion.respectReducedMotion(context, VocaMotion.quick),
            curve: VocaMotion.standardCurve,
            margin: const EdgeInsets.symmetric(horizontal: VocaSpacing.xxs),
            height: 6,
            width: active ? 22 : 6,
            decoration: BoxDecoration(
              color: active ? colors.primary : colors.borderStrong,
              borderRadius: VocaRadius.pillAll,
            ),
          );
        }),
      ),
    );
  }
}
