/// A selectable glass card.
///
/// Used by every setup screen. Selection is shown three ways at once, not one: a filled
/// check mark, a coloured border, and a tinted surface. Relying on colour alone would
/// leave the state invisible to someone who cannot distinguish it.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_glass.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_badge.dart';

class SelectionCard extends StatelessWidget {
  const SelectionCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.badge,
  });

  final String title;
  final String? subtitle;

  /// A short marker such as a CEFR code.
  final String? leading;

  /// An optional pill, for example the recommended option.
  final String? badge;

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final glass = context.vocaGlass;
    final text = context.vocaText;
    final radius = BorderRadius.circular(VocaRadius.large);

    return Semantics(
      button: true,
      selected: selected,
      label: subtitle == null ? title : '$title. $subtitle',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: VocaMotion.respectReducedMotion(context, VocaMotion.quick),
          curve: VocaMotion.standardCurve,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(
            horizontal: VocaSpacing.md,
            vertical: VocaSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? colors.primaryMuted : glass.tint,
            borderRadius: radius,
            border: Border.all(
              color: selected ? colors.primary : glass.borderBottom,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                Container(
                  width: 44,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: VocaSpacing.xxs),
                  decoration: BoxDecoration(
                    color: selected ? colors.primary : colors.border,
                    borderRadius: VocaRadius.smallAll,
                  ),
                  child: Text(
                    leading!,
                    style: text.label.copyWith(
                      color: selected ? colors.onPrimary : colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: VocaSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: text.subtitle.copyWith(color: colors.textPrimary),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: VocaSpacing.xs),
                          AppBadge(label: badge!, tone: BadgeTone.primary),
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: text.caption.copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: VocaSpacing.xs),
              AnimatedOpacity(
                duration: VocaMotion.respectReducedMotion(context, VocaMotion.quick),
                opacity: selected ? 1 : 0,
                child: Icon(Icons.check_circle_rounded, color: colors.primary, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
