/// The bottom navigation for the signed-in app.
///
/// A floating pill of clear glass holding four liquid drops. The pill is kept thin on
/// purpose, so the liquid behind the page shows through it; the drops carry the weight.
///
/// * Each destination sits in a small glass bead: a lit face up and to the left, a rim,
///   a shadow underneath, and a faint bright spot at the bottom where the light that
///   passed through it lands. That last detail is most of what makes a circle read as a
///   drop.
/// * The selected destination is marked by a drop of brand-coloured liquid that travels
///   between the beads. On the way it stretches along the direction it moves and settles
///   with a slight overshoot, which is how liquid moves and a sliding tab does not.
///
/// The active item is marked three ways, never by colour alone: the brand drop, a filled
/// icon, and its label in the heavier weight. With reduced motion the drop moves in one
/// step, without stretching.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_glass.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'glass_surface.dart';
import 'liquid_drop.dart';

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

class LiquidBottomBar extends StatefulWidget {
  const LiquidBottomBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<LiquidNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// How much of the theme's glass tint the bar carries. Far thinner than a card: the
  /// bar holds no body text, only short labels in the strong text colours, and those stay
  /// readable over the liquid with no tint at all (contrast_test).
  @visibleForTesting
  static const lightGlassAlpha = 0.26;
  @visibleForTesting
  static const darkGlassAlpha = 0.40;

  @override
  State<LiquidBottomBar> createState() => _LiquidBottomBarState();
}

class _LiquidBottomBarState extends State<LiquidBottomBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _travel = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
    value: 1,
  );

  // Where the drop is travelling from and to, as item positions. Fractional mid-flight.
  late double _from = widget.currentIndex.toDouble();
  late double _to = _from;

  // easeOutBack overshoots a little and comes back: the drop sloshes past its target
  // and settles, instead of stopping dead.
  double get _position =>
      lerpDouble(_from, _to, Curves.easeOutBack.transform(_travel.value))!;

  @override
  void didUpdateWidget(LiquidBottomBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex == widget.currentIndex) return;
    // Start from wherever the drop is now, so a second tap mid-flight redirects it
    // instead of snapping it back.
    _from = _position;
    _to = widget.currentIndex.toDouble();
    if (MediaQuery.disableAnimationsOf(context)) {
      _travel.value = 1;
    } else {
      _travel.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _travel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.vocaGlass;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: VocaSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: VocaSpacing.md),
        child: GlassSurface(
          borderRadius: BorderRadius.circular(VocaRadius.pill),
          tint: glass.tint.withValues(
            alpha: dark
                ? LiquidBottomBar.darkGlassAlpha
                : LiquidBottomBar.lightGlassAlpha,
          ),
          borderWidth: 1.2,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / widget.items.length;
              return AnimatedBuilder(
                animation: _travel,
                builder: (context, _) {
                  final position = _position;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _drop(position, itemWidth),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < widget.items.length; i++)
                            Expanded(
                              // A stable key per position, so tests and automation can
                              // find a destination without depending on its label.
                              key: ValueKey('liquid-nav-$i'),
                              child: _NavButton(
                                item: widget.items[i],
                                selected: i == widget.currentIndex,
                                coverage: (1 - (position - i).abs()).clamp(
                                  0.0,
                                  1.0,
                                ),
                                onTap: () => widget.onTap(i),
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  /// The brand drop at [position], stretched by how fast and how far it is moving.
  Widget _drop(double position, double itemWidth) {
    final t = _travel.value.clamp(0.0, 1.0);
    final distance = (_to - _from).abs().clamp(0.0, 3.0);
    // Stretch peaks mid-flight and grows with the distance. The drop thins a little as
    // it lengthens, so its volume looks conserved.
    final stretch = math.sin(math.pi * t) * distance * itemWidth * 0.3;
    final width = math.min(_NavButton.dropSize + stretch, itemWidth * 1.5);
    final height = _NavButton.dropSize - math.min(stretch * 0.08, 6.0);

    return Positioned(
      left: (position + 0.5) * itemWidth - width / 2,
      top: _NavButton.dropTop + (_NavButton.dropSize - height) / 2,
      width: width,
      height: height,
      child: const IgnorePointer(child: ExcludeSemantics(child: LiquidDrop())),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.coverage,
    required this.onTap,
  });

  static const dropSize = 40.0;
  static const dropTop = 7.0;

  final LiquidNavItem item;
  final bool selected;

  /// How much of this item the brand drop covers right now, 0 to 1.
  final double coverage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    // The icon turns as the drop reaches it, not when the tap lands, so it is never
    // white on clear glass while the drop is still on its way.
    final iconColor = Color.lerp(
      colors.textSecondary,
      colors.onPrimary,
      coverage,
    )!;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          // With the label this is well over the 48 point minimum touch target.
          padding: const EdgeInsets.only(top: dropTop, bottom: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: dropSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // The bead fades as the brand drop arrives, so the two never show
                    // at once.
                    Positioned.fill(
                      child: Opacity(
                        opacity: 1 - coverage,
                        child: const GlassBead(),
                      ),
                    ),
                    Icon(
                      selected ? item.activeIcon : item.icon,
                      size: 22,
                      color: iconColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: text.caption.copyWith(
                  color: selected ? colors.textPrimary : colors.textSecondary,
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
