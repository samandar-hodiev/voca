/// A single number worth looking at, with what it means.
///
/// Solid rather than glass. The dashboard holds several of these side by side, and a grid
/// of translucent panes turns the page into frosted noise; glass is reserved for the one
/// thing that floats.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'glass_surface.dart';
import 'liquid_drop.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.caption,
    this.accent,
  });

  final String label;
  final String value;
  final IconData? icon;

  /// A short line under the value, such as a change since last week.
  final String? caption;

  /// Tints the icon. Defaults to the brand colour; the value itself stays in body text so
  /// the number never depends on colour to be read.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    final tint = accent ?? colors.primary;

    return Semantics(
      container: true,
      label: caption == null ? '$label: $value' : '$label: $value. $caption',
      child: ExcludeSemantics(
        child: GlassSurface(
          blur: false,
          padding: const EdgeInsets.all(VocaSpacing.md),
          borderRadius: BorderRadius.circular(VocaRadius.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    LiquidDrop(
                      color: tint,
                      glow: false,
                      borderRadius: BorderRadius.circular(VocaRadius.small),
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        icon,
                        size: 16,
                        color: LiquidDrop.foregroundOn(tint),
                      ),
                    ),
                    const SizedBox(width: VocaSpacing.xs),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: text.caption.copyWith(color: colors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VocaSpacing.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: text.headline.copyWith(color: colors.textPrimary),
                ),
              ),
              if (caption != null) ...[
                const SizedBox(height: 2),
                Text(
                  caption!,
                  style: text.caption.copyWith(color: colors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Two stat cards side by side, stacked when the screen is too narrow for both.
///
/// Home and Progress both pair their numbers this way, so the breakpoint lives in one
/// place. Side by side, the pair is stretched to one height so neither card looks broken
/// when their captions wrap differently.
class StatPair extends StatelessWidget {
  const StatPair({super.key, required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth < 340) {
          return Column(
            children: [
              left,
              const SizedBox(height: VocaSpacing.sm),
              right,
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: left),
              const SizedBox(width: VocaSpacing.sm),
              Expanded(child: right),
            ],
          ),
        );
      },
    );
  }
}
