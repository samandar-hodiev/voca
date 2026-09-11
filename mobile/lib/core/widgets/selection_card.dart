/// A selectable glass card.
///
/// Used by every setup screen. Selection is shown three ways at once, not one: a filled
/// check mark, a coloured border, and a tinted surface. Relying on colour alone would
/// leave the state invisible to someone who cannot distinguish it.
///
/// The pane is a real [GlassSurface], not a rounded box with a pale fill. A flat fill on
/// a light page is a white card whatever the token is called; the blur, the lit top face
/// and the gradient rim are what make it read as glass, and the tint is thin enough that
/// the liquid field behind shows through it.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_glass.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_badge.dart';
import 'glass_surface.dart';
import 'liquid_drop.dart';
import 'glass_touch_light.dart';

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
        child: Stack(
          children: [
            GlassTouchLight(
              borderRadius: radius,
              child: GlassSurface(
                edgeGlow: false,
                borderRadius: radius,
                // Selected thickens the pane and pulls it toward the brand colour, so the
                // choice reads even before the check mark is noticed.
                // Barely there on purpose. A fill heavy enough to hide the field behind it
                // is a white card, whatever it is called. Selection is carried by the ring
                // and the check mark, so the selected pane only has to shift hue.
                tint: glass.tint.withValues(alpha: glass.controlOpacity),
                tintGradient: selected
                    ? LinearGradient(
                        colors: [
                          colors.primary.withValues(alpha: 0.18),
                          LiquidDrop.brandTeal(
                            Theme.of(context).brightness,
                          ).withValues(alpha: 0.04),
                        ],
                      )
                    : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: VocaSpacing.md,
                  vertical: VocaSpacing.sm,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    children: [
                      if (leading != null) ...[
                        SizedBox(
                          width: 44,
                          child: selected
                              ? LiquidDrop(
                                  glow: false,
                                  borderRadius: VocaRadius.smallAll,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: VocaSpacing.xxs,
                                  ),
                                  child: Center(
                                    child: Text(
                                      leading!,
                                      style: text.label.copyWith(
                                        color: colors.onPrimary,
                                      ),
                                    ),
                                  ),
                                )
                              : GlassBead(
                                  borderRadius: VocaRadius.smallAll,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: VocaSpacing.xxs,
                                  ),
                                  child: Center(
                                    child: Text(
                                      leading!,
                                      style: text.label.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
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
                                    style: text.subtitle.copyWith(
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (badge != null) ...[
                                  const SizedBox(width: VocaSpacing.xs),
                                  AppBadge(
                                    label: badge!,
                                    tone: BadgeTone.primary,
                                  ),
                                ],
                              ],
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle!,
                                style: text.caption.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: VocaSpacing.xs),
                      AnimatedOpacity(
                        duration: VocaMotion.respectReducedMotion(
                          context,
                          VocaMotion.quick,
                        ),
                        opacity: selected ? 1 : 0,
                        child: SizedBox.square(
                          dimension: 22,
                          child: LiquidDrop(
                            glow: false,
                            child: Icon(
                              Icons.check_rounded,
                              color: colors.onPrimary,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // The selected ring is painted over the pane rather than replacing its rim.
            // The gradient rim is what makes the surface glass; a solid border swapped in
            // its place would flatten the selected card back into a plain box.
            if (selected)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: GradientBoxBorder(
                        width: 1.5,
                        gradient: LinearGradient(
                          colors: [
                            colors.primary,
                            LiquidDrop.brandTeal(
                              Theme.of(context).brightness,
                            ).withValues(alpha: 0.35),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
