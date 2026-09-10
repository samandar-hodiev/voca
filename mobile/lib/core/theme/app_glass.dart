/// Glass surface tokens.
///
/// Voca's direction is glassmorphism-INSPIRED, used with restraint. Glass marks a surface
/// as floating above the page; it is not a texture to apply everywhere. A screen where
/// everything is glass has no hierarchy, and it is exactly the template look the product
/// is trying not to have.
///
/// Two rules govern every value here:
///
/// 1. **Blur stays low.** Heavy blur is expensive on mid-range Android and turns the
///    background into noise behind text.
/// 2. **Contrast outranks the effect.** The tint is opaque enough that body text on glass
///    still meets contrast requirements. If a value here ever fights readability, the
///    value loses.
library;

import 'package:flutter/material.dart';

import 'app_radius.dart';

/// Glass appearance for one brightness.
@immutable
class VocaGlass extends ThemeExtension<VocaGlass> {
  const VocaGlass({
    required this.tint,
    required this.borderColor,
    required this.blurSigma,
    required this.radius,
    required this.shadows,
  });

  /// The translucent fill. Opaque enough to keep text legible over any background.
  final Color tint;

  /// A hairline edge. Glass reads as a distinct surface only if its edge is visible.
  final Color borderColor;

  /// Backdrop blur sigma. Deliberately modest.
  final double blurSigma;

  /// Corner radius for glass surfaces.
  final double radius;

  /// Soft, wide, low-opacity shadow. Depth comes from softness, not darkness.
  final List<BoxShadow> shadows;

  static const light = VocaGlass(
    tint: Color(0xCCFFFFFF),
    borderColor: Color(0x33FFFFFF),
    blurSigma: 18,
    radius: VocaRadius.large,
    shadows: [
      BoxShadow(
        color: Color(0x14111827),
        blurRadius: 32,
        offset: Offset(0, 12),
      ),
      BoxShadow(
        color: Color(0x0A111827),
        blurRadius: 4,
        offset: Offset(0, 1),
      ),
    ],
  );

  static const dark = VocaGlass(
    tint: Color(0xCC1B212C),
    borderColor: Color(0x1FFFFFFF),
    blurSigma: 18,
    radius: VocaRadius.large,
    shadows: [
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 32,
        offset: Offset(0, 12),
      ),
    ],
  );

  @override
  VocaGlass copyWith({
    Color? tint,
    Color? borderColor,
    double? blurSigma,
    double? radius,
    List<BoxShadow>? shadows,
  }) {
    return VocaGlass(
      tint: tint ?? this.tint,
      borderColor: borderColor ?? this.borderColor,
      blurSigma: blurSigma ?? this.blurSigma,
      radius: radius ?? this.radius,
      shadows: shadows ?? this.shadows,
    );
  }

  @override
  VocaGlass lerp(covariant VocaGlass? other, double t) {
    if (other == null) return this;
    return VocaGlass(
      tint: Color.lerp(tint, other.tint, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t),
      radius: lerpDouble(radius, other.radius, t),
      shadows: BoxShadow.lerpList(shadows, other.shadows, t) ?? shadows,
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

extension VocaGlassX on BuildContext {
  VocaGlass get vocaGlass =>
      Theme.of(this).extension<VocaGlass>() ?? VocaGlass.light;
}
