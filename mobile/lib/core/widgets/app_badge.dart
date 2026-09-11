/// A small status pill.
///
/// [BadgeTone] names the MEANING, not the colour, so a badge cannot drift away from the
/// semantic palette.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'liquid_drop.dart';

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

  /// How much of its tone a badge carries: half, so the glass behind shows through.
  /// Public so the contrast test checks every tone at this strength on glass.
  @visibleForTesting
  static const tintAlpha = 0.5;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final (background, foreground) = switch (tone) {
      BadgeTone.neutral => (colors.border, colors.textSecondary),
      BadgeTone.primary => (colors.primaryMuted, colors.onPrimaryMuted),
      BadgeTone.success => (colors.successMuted, colors.onSuccessMuted),
      BadgeTone.warning => (colors.warningMuted, colors.onWarningMuted),
      BadgeTone.error => (colors.errorMuted, colors.onErrorMuted),
    };

    // A clear glass pill carrying half its tone (contrast_test checks every tone on glass).
    return GlassBead(
      tint: background.withValues(alpha: tintAlpha),
      padding: const EdgeInsets.symmetric(
        horizontal: VocaSpacing.xs,
        vertical: VocaSpacing.xxs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: VocaSpacing.xxs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.vocaText.caption.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
