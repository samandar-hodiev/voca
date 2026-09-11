/// Tinted and clear glass for controls, after iOS Liquid Glass.
///
/// * [LiquidDrop] is glass tinted with a colour, the way iOS draws a prominent button or
///   a filled control: the colour itself, a faint light across the top, and a hairline
///   rim that catches the light. No glints, no glow.
/// * [GlassBead] is clear glass for small controls and wells: a thin fill and a hairline
///   rim.
///
/// Both stay quiet on purpose. Glossy highlights and coloured glows are what make glass
/// look like a cartoon.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import 'glass_surface.dart';

/// Glass tinted with [color], with [child] on it.
class LiquidDrop extends StatelessWidget {
  const LiquidDrop({
    super.key,
    this.child,
    this.color,
    this.borderRadius,
    this.padding,
    this.glow = false,
  });

  final Widget? child;

  /// The tint. Defaults to the brand colour.
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  /// A soft, neutral shadow under a control that floats, such as the primary button.
  final bool glow;

  /// How much white the top edge carries, per theme.
  static const topLightenLight = 0.18;
  static const topLightenDark = 0.20;

  /// A whisper of shade along the bottom edge, per theme: enough for a little volume,
  /// not enough to muddy the colour.
  static const shadeLight = 0.12;
  static const shadeDark = 0.14;

  /// Where, as a fraction of the height, the light at the top has faded out. A label's
  /// band starts at [labelBandTop], so everything behind a label is the plain colour.
  /// Public so the contrast test holds the two to each other.
  static const colourStop = 0.30;
  static const labelBandTop = 0.30;

  /// The teal the brand colour flows into across a filled control, per theme. White (in
  /// light) and near-black (in dark) keep their contrast on it; contrast_test checks.
  static Color brandTeal(Brightness brightness) => brightness == Brightness.dark
      ? const Color(0xFF2DD4BF)
      : const Color(0xFF0F766E);

  /// Whichever of white and near-black reads better on [color].
  static Color foregroundOn(Color color) {
    const dark = Color(0xFF0B0F17);
    final l = color.computeLuminance();
    final onWhite = 1.05 / (l + 0.05);
    final onDark = (l + 0.05) / (dark.computeLuminance() + 0.05);
    return onWhite >= onDark ? Colors.white : dark;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? VocaRadius.pillAll;
    final top = dark ? topLightenDark : topLightenLight;
    final base = color ?? colors.primary;
    // The brand runs diagonally from emerald into teal; any other colour stays itself.
    final brand = base == colors.primary || base == colors.primaryPressed;
    final end = brand
        ? Color.lerp(base, brandTeal(Theme.of(context).brightness), 0.9)!
        : base;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, end],
        ),
        borderRadius: radius,
        boxShadow: glow
            ? const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 14,
                  spreadRadius: -4,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: top),
              Colors.white.withValues(alpha: 0),
              Colors.black.withValues(alpha: dark ? shadeDark : shadeLight),
            ],
            stops: const [0, colourStop, 1],
          ),
          border: GradientBoxBorder(
            width: 0.8,
            gradient: specularRim(
              Colors.white.withValues(alpha: 0.6),
              Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ),
        child: padding == null
            ? child
            : Padding(padding: padding!, child: child),
      ),
    );
  }
}

/// Clear glass, with [child] seen through it.
class GlassBead extends StatelessWidget {
  const GlassBead({
    super.key,
    this.child,
    this.borderRadius,
    this.padding,
    this.tint,
    this.size,
  });

  final Widget? child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  /// A colour laid into the glass, for a well that belongs to a state such as the brand
  /// or an error.
  final Color? tint;

  /// Width and height, for a well of a fixed size.
  final double? size;

  /// The clear fill at its lightest, along the top, per theme. It fades to about half by
  /// the bottom. Public so the contrast test checks text on the lightest part.
  static Color fill(Brightness brightness) => brightness == Brightness.dark
      ? const Color(0x0FFFFFFF)
      : const Color(0x38FFFFFF);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final dark = brightness == Brightness.dark;
    final radius = borderRadius ?? VocaRadius.pillAll;
    final body = padding == null
        ? child
        : Padding(padding: padding!, child: child);

    final bead = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            fill(brightness),
            fill(brightness).withValues(alpha: fill(brightness).a * 0.55),
          ],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tint,
          borderRadius: radius,
          border: GradientBoxBorder(
            width: 0.8,
            gradient: dark
                ? specularRim(const Color(0x59FFFFFF), const Color(0x0DFFFFFF))
                : specularRim(const Color(0xFFFFFFFF), const Color(0x1A000000)),
          ),
        ),
        // A little volume: light gathered across the top of the well.
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: dark ? 0.12 : 0.32),
                Colors.white.withValues(alpha: 0),
              ],
              stops: const [0, 0.35],
            ),
          ),
          child: body,
        ),
      ),
    );

    return size == null ? bead : SizedBox.square(dimension: size, child: bead);
  }
}

/// The premium green glass of the primary action and the selected tab: a mint-to-emerald
/// liquid carrying a deep green label. Light and clear, rather than a dark slab of ink.
abstract final class PremiumGreen {
  static const start = Color(0xFFA7F3D0);
  static const end = Color(0xFF34D399);
  static const pressedStart = Color(0xFF6EE7B7);
  static const pressedEnd = Color(0xFF10B981);

  /// How much of the colour the glass carries: enough to be green, clear enough that
  /// what is behind still shows through.
  static const alpha = 0.88;

  /// The label on the glass. A deep green, which reads on it in both themes
  /// (contrast_test).
  static const label = Color(0xFF022C22);
}
