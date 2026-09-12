/// The bottom navigation for the signed-in app.
///
/// The design follows a reference tab bar the product owner chose, on top of Apple's
/// Liquid Glass: a
/// tall capsule of clear glass with a thin light rim, outline icons at rest, and the
/// selected destination sitting in a pill of liquid glass with its icon filled. The bar
/// is genuinely see-through: it blurs what passes under it only lightly and carries almost
/// no tint, and its volume comes from light at the rim, the edge and the caustic. The
/// pill is a small body of liquid glass, lit across the top and a touch deeper at the
/// bottom, and it slides to a new destination, stretching a little on the way and
/// settling with a slight overshoot.
///
/// The destinations, icons and labels are Voca's own; only the design comes from the
/// reference. The active item is marked three ways, never by colour alone: the pill, a
/// filled icon, and its label in the heavier weight. With reduced motion the pill moves
/// in one step.
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
import 'glass_touch_light.dart';
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

  /// How much of the theme's glass tint the bar carries: clear. The labels stay readable
  /// over the background with no tint at all (contrast_test).
  @visibleForTesting
  static const lightGlassAlpha = 0.12;
  @visibleForTesting
  static const darkGlassAlpha = 0.20;

  /// How much of the premium green the selected pill carries in the light theme.
  @visibleForTesting
  static const greenPillAlpha = 0.82;

  /// The pill behind the selected destination, per theme.
  @visibleForTesting
  static Color lensFill(Brightness brightness) => brightness == Brightness.dark
      ? const Color(0x24FFFFFF)
      : const Color(0x73FFFFFF);

  /// The light across the top of the pill, per theme. Public so the contrast test checks
  /// the selected label on the pill's lightest part.
  @visibleForTesting
  static Color lensTopLight(Brightness brightness) =>
      brightness == Brightness.dark
      ? const Color(0x1FFFFFFF)
      : const Color(0x99FFFFFF);

  @override
  State<LiquidBottomBar> createState() => _LiquidBottomBarState();
}

class _LiquidBottomBarState extends State<LiquidBottomBar>
    with SingleTickerProviderStateMixin {
  // A gentle overshoot: the pill flows past its target by a hair and settles.
  static const _settle = Cubic(0.34, 1.26, 0.64, 1);

  late final AnimationController _travel = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
    value: 1,
  );

  // Where the pill is travelling from and to, as item positions. Fractional mid-flight.
  late double _from = widget.currentIndex.toDouble();
  late double _to = _from;

  double get _position =>
      lerpDouble(_from, _to, _settle.transform(_travel.value))!;

  @override
  void didUpdateWidget(LiquidBottomBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex == widget.currentIndex) return;
    // Start from wherever the pill is now, so a second tap mid-flight redirects it.
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
          edgeGlow: false,
          // Clear glass with volume: light across the top and a caustic along the
          // bottom where light that crossed the glass comes out, and almost nothing in
          // between, so what is under the bar shows through it.
          tintGradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? const [
                    Color(0x0FFFFFFF),
                    Color(0x00FFFFFF),
                    Color(0x14FFFFFF),
                  ]
                : const [
                    Color(0x24FFFFFF),
                    Color(0x00FFFFFF),
                    Color(0x2EFFFFFF),
                  ],
            stops: const [0, 0.5, 1],
          ),
          blurSigma: 6,
          highlight: Color(dark ? 0x14FFFFFF : 0x66FFFFFF),
          rimTop: Color(dark ? 0x59FFFFFF : 0xFFFFFFFF),
          rimBottom: Color(dark ? 0x33FFFFFF : 0xB3FFFFFF),
          edgeLight: Color(dark ? 0x40FFFFFF : 0xE6FFFFFF),
          borderWidth: 1.2,
          shadows: [
            BoxShadow(
              color: Color(dark ? 0x66000000 : 0x330F3D2E),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Color(dark ? 0x40000000 : 0x330F3D2E),
              blurRadius: 1.5,
              spreadRadius: 0.7,
            ),
          ],
          borderRadius: BorderRadius.circular(VocaRadius.pill),
          tint: glass.tint.withValues(
            alpha: dark
                ? LiquidBottomBar.darkGlassAlpha
                : LiquidBottomBar.lightGlassAlpha,
          ),
          padding: const EdgeInsets.all(6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / widget.items.length;
              return AnimatedBuilder(
                animation: _travel,
                builder: (context, _) {
                  final position = _position;
                  return Stack(
                    children: [
                      _pill(position, itemWidth),
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

  /// The pill at [position], a little wider while it moves.
  Widget _pill(double position, double itemWidth) {
    final t = _travel.value.clamp(0.0, 1.0);
    final distance = (_to - _from).abs().clamp(0.0, 3.0);
    final stretch = math.min(
      math.sin(math.pi * t) * distance * itemWidth * 0.22,
      itemWidth * 0.8,
    );
    final width = itemWidth - 4 + stretch;

    return Positioned(
      left: (position + 0.5) * itemWidth - width / 2,
      top: 0,
      bottom: 0,
      width: width,
      child: const IgnorePointer(child: ExcludeSemantics(child: _Pill())),
    );
  }
}

/// The lighter glass behind the selected destination: a small body of liquid glass, lit
/// across the top and a touch deeper at the bottom, with a specular rim.
class _Pill extends StatelessWidget {
  const _Pill();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final dark = brightness == Brightness.dark;
    final radius = BorderRadius.circular(VocaRadius.pill);

    final colors = context.vocaColors;
    if (!dark) {
      // In light, the pill is the same premium green glass as the primary button: a
      // mint-to-emerald liquid with a specular band across the top, a caustic along the
      // bottom, a bright rim and a soft green glow, so the selected tab reads as liquid.
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              PremiumGreen.start.withValues(
                alpha: LiquidBottomBar.greenPillAlpha,
              ),
              PremiumGreen.end.withValues(
                alpha: LiquidBottomBar.greenPillAlpha,
              ),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: PremiumGreen.end.withValues(alpha: 0.35),
              blurRadius: 14,
              spreadRadius: -3,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.6),
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.25),
              ],
              stops: const [0, 0.45, 0.78, 1],
            ),
            border: GradientBoxBorder(
              width: 1.2,
              gradient: specularRim(
                Colors.white,
                Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      );
    }
    final fill = LiquidBottomBar.lensFill(brightness);
    return DecoratedBox(
      // Clear glass with the faintest emerald-to-teal tint, the liquid in the pill.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(colors.primary.withValues(alpha: 0.10), fill),
            Color.alphaBlend(
              LiquidDrop.brandTeal(brightness).withValues(alpha: 0.05),
              fill,
            ),
          ],
        ),
        borderRadius: radius,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              LiquidBottomBar.lensTopLight(brightness),
              LiquidBottomBar.lensTopLight(brightness).withValues(alpha: 0),
              Colors.black.withValues(alpha: 0),
              Colors.black.withValues(alpha: dark ? 0.16 : 0.05),
            ],
            stops: const [0, 0.45, 0.7, 1],
          ),
          border: GradientBoxBorder(
            width: 1.2,
            gradient: dark
                ? specularRim(const Color(0x66FFFFFF), const Color(0x14FFFFFF))
                : specularRim(const Color(0xE6FFFFFF), const Color(0x40FFFFFF)),
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

  /// How much of this item the pill covers right now, 0 to 1.
  final double coverage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    // Neutral, as in the reference: the selected icon is the strong text colour, the
    // rest the quieter one. The colour follows the pill, so it arrives with it.
    final foreground = Color.lerp(
      colors.textSecondary,
      Theme.of(context).brightness == Brightness.dark
          ? colors.textPrimary
          : PremiumGreen.label,
      coverage,
    )!;
    // A soft halo behind icon and label, so they stay legible over whatever passes
    // under the clear glass.
    final halo = [
      Shadow(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xB3000000)
            : const Color(0xCCFFFFFF),
        blurRadius: 8,
      ),
    ];

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: GlassTouchLight(
          borderRadius: BorderRadius.circular(VocaRadius.pill),
          child: Padding(
            // Well over the 48 point minimum touch target.
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 24,
                  color: foreground,
                  shadows: halo,
                ),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: text.caption.copyWith(
                    fontSize: 11,
                    color: foreground,
                    shadows: halo,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
