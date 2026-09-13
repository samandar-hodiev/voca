/// One piece of advice: what went wrong, and what to do with your mouth about it.
///
/// The second line is the part that teaches. "Your θ was wrong" is a verdict; "put your
/// tongue tip between your teeth and blow" is a thing a person can act on immediately.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_surface.dart';

class FeedbackTip extends StatelessWidget {
  const FeedbackTip({super.key, required this.message, this.tip});

  final String message;
  final String? tip;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;

    return Padding(
      padding: const EdgeInsets.only(bottom: VocaSpacing.xs),
      child: GlassSurface(
        borderRadius: VocaRadius.largeAll,
        padding: const EdgeInsets.all(VocaSpacing.sm),
        // Stacked inside a card that already casts one; a second shadow under each item
        // reads as a band of darker background behind the group.
        showShadow: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              size: 18,
              color: colors.primary,
            ),
            const SizedBox(width: VocaSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: text.bodyMedium.copyWith(color: colors.textPrimary),
                  ),
                  if (tip != null) ...[
                    const SizedBox(height: VocaSpacing.xxs),
                    Text(
                      tip!,
                      style: text.caption.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
