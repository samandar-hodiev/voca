/// The bottom navigation for the signed-in app.
///
/// A floating glass pill rather than a full-width bar. Floating is what lets the liquid
/// field show round it, and the pill shape keeps it reading as one control instead of a
/// strip of chrome. It is the one piece of persistent glass in the shell: the content
/// cards underneath are deliberately more solid, so the bar is what floats.
///
/// The active item is marked three ways, never by colour alone: a lit capsule behind it,
/// a filled icon, and its label in the heavier weight.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_glass.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'glass_surface.dart';

/// One destination in the bar.
@immutable
class LiquidNavItem {
  const LiquidNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class LiquidBottomBar extends StatelessWidget {
  const LiquidBottomBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<LiquidNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.vocaGlass;
    final radius = BorderRadius.circular(VocaRadius.pill);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: VocaSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: VocaSpacing.md),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: glass.shadows,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: glass.blurSigma,
                sigmaY: glass.blurSigma,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  // Thicker than a control: the bar sits over content that scrolls, and a
                  // label has to stay readable over whatever passes underneath.
                  color: glass.tint.withValues(
                    alpha: (glass.controlOpacity + 0.35).clamp(0.0, 1.0),
                  ),
                  borderRadius: radius,
                  border: GradientBoxBorder(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [glass.borderTop, glass.borderBottom],
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(VocaSpacing.xxs + 2),
                  child: Row(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Expanded(
                          // A stable key per position, so tests and automation can find
                          // a destination without depending on its translated label.
                          key: ValueKey('liquid-nav-$i'),
                          child: _NavButton(
                            item: items[i],
                            selected: i == currentIndex,
                            onTap: () => onTap(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final LiquidNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    final duration = VocaMotion.respectReducedMotion(context, VocaMotion.quick);
    final foreground = selected ? colors.onPrimaryMuted : colors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: AnimatedContainer(
          duration: duration,
          curve: VocaMotion.standardCurve,
          // 56 clears the 48 point minimum touch target with room for the label.
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(VocaRadius.pill),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.08 : 1,
                duration: duration,
                curve: VocaMotion.standardCurve,
                child: Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 22,
                  color: foreground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: text.caption.copyWith(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
