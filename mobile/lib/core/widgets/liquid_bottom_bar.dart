/// The bottom navigation for the signed-in app, after the iOS 26 tab bar.
///
/// A floating capsule of clear glass. The destinations sit in it as plain icons and
/// labels; the selected one gets a lighter lens of glass behind it. When the selection
/// moves, the lens slides to the new destination, stretching a little on the way and
/// settling with a slight overshoot, the way the iOS lens flows between tabs.
///
/// The active item is marked three ways, never by colour alone: the lens, a filled icon,
/// and its label in the heavier weight and the accent colour. With reduced motion the
/// lens moves in one step.
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

  /// How much of the theme's glass tint the bar carries: clear, as iOS draws it. The
  /// labels stay readable over the background with no tint at all (contrast_test).
  @visibleForTesting
  static const lightGlassAlpha = 0.42;
  @visibleForTesting
  static const darkGlassAlpha = 0.55;

  /// The lens behind the selected destination, per theme.
  @visibleForTesting
  static Color lensFill(Brightness brightness) => brightness == Brightness.dark
      ? const Color(0x1AFFFFFF)
      : const Color(0xA6FFFFFF);

  @override
  State<LiquidBottomBar> createState() => _LiquidBottomBarState();
}

class _LiquidBottomBarState extends State<LiquidBottomBar>
    with SingleTickerProviderStateMixin {
  // A gentle overshoot: the lens flows past its target by a hair and settles.
  static const _settle = Cubic(0.34, 1.26, 0.64, 1);

  late final AnimationController _travel = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
    value: 1,
  );

  // Where the lens is travelling from and to, as item positions. Fractional mid-flight.
  late double _from = widget.currentIndex.toDouble();
  late double _to = _from;

  double get _position =>
      lerpDouble(_from, _to, _settle.transform(_travel.value))!;

  @override
  void didUpdateWidget(LiquidBottomBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex == widget.currentIndex) return;
    // Start from wherever the lens is now, so a second tap mid-flight redirects it.
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
        padding: const EdgeInsets.symmetric(horizontal: VocaSpacing.lg),
        child: GlassSurface(
          borderRadius: BorderRadius.circular(VocaRadius.pill),
          tint: glass.tint.withValues(
            alpha: dark
                ? LiquidBottomBar.darkGlassAlpha
                : LiquidBottomBar.lightGlassAlpha,
          ),
          padding: const EdgeInsets.all(4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / widget.items.length;
              return AnimatedBuilder(
                animation: _travel,
                builder: (context, _) {
                  final position = _position;
                  return Stack(
                    children: [
                      _lens(position, itemWidth),
                      Row(
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

  /// The lens at [position], a little wider while it moves.
  Widget _lens(double position, double itemWidth) {
    final t = _travel.value.clamp(0.0, 1.0);
    final distance = (_to - _from).abs().clamp(0.0, 3.0);
    final stretch = math.min(
      math.sin(math.pi * t) * distance * itemWidth * 0.22,
      itemWidth * 0.8,
    );
    final width = itemWidth + stretch;

    return Positioned(
      left: (position + 0.5) * itemWidth - width / 2,
      top: 0,
      bottom: 0,
      width: width,
      child: const IgnorePointer(child: ExcludeSemantics(child: _Lens())),
    );
  }
}

/// The lighter glass behind the selected destination.
class _Lens extends StatelessWidget {
  const _Lens();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final dark = brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            LiquidBottomBar.lensFill(brightness),
            LiquidBottomBar.lensFill(
              brightness,
            ).withValues(alpha: LiquidBottomBar.lensFill(brightness).a * 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(VocaRadius.pill),
        border: GradientBoxBorder(
          width: 0.8,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? const [Color(0x4DFFFFFF), Color(0x0DFFFFFF)]
                : const [Color(0xFFFFFFFF), Color(0x0F000000)],
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
    required this.coverage,
    required this.onTap,
  });

  final LiquidNavItem item;
  final bool selected;

  /// How much of this item the lens covers right now, 0 to 1.
  final double coverage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    // The colour follows the lens, so the accent arrives with it rather than ahead of it.
    final foreground = Color.lerp(
      colors.textSecondary,
      colors.onPrimaryMuted,
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
          // With the label this is over the 48 point minimum touch target.
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? item.activeIcon : item.icon,
                size: 24,
                color: foreground,
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: text.caption.copyWith(
                  fontSize: 11,
                  color: foreground,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
