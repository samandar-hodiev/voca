/// A small status pill.
///
/// [BadgeTone] names the MEANING, not the colour, so a badge cannot drift away from the
/// semantic palette.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum BadgeTone { neutral, primary, success, warning, error }

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.tone = BadgeTone.neutral,
    this.icon,
  });

  final String label;
  final BadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final (background, foreground) = switch (tone) {
      BadgeTone.neutral => (colors.border, colors.textSecondary),
      BadgeTone.primary => (colors.primaryMuted, colors.primary),
      BadgeTone.success => (colors.successMuted, colors.onSuccessMuted),
      BadgeTone.warning => (colors.warningMuted, colors.onWarningMuted),
      BadgeTone.error => (colors.errorMuted, colors.onErrorMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VocaSpacing.xs,
        vertical: VocaSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: VocaRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: VocaSpacing.xxs),
          ],
          Text(
            label,
            style: context.vocaText.caption.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
