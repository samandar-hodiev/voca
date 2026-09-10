/// Glass surface tokens.
///
/// Glass marks a surface as floating above the page. It only reads as glass if the layer
/// behind it is actually visible through it, which means three things have to be true at
/// once:
///
/// 1. **The fill is genuinely translucent.** An 80%-opaque white is a white card with
///    extra steps. The tint sits near 65%: transparent enough that the liquid field below
///    reads through it, opaque enough that dark body text on top still clears its
///    contrast requirement.
/// 2. **The edge catches light.** Real glass has a bright rim where light enters and a
///    dimmer one where it leaves. A single flat border line does not read as glass; the
///    gradient border is what gives the surface its edge.
/// 3. **The top face is lit.** A soft highlight fading down the surface is what makes it
///    look like a solid pane rather than a hole cut in the page.
///
/// Contrast still outranks all of it. The tint stays opaque enough that dark body text on
/// glass clears its contrast requirement over the light liquid field beneath.
library;

import 'package:flutter/material.dart';

import 'app_radius.dart';

/// Glass appearance for one brightness.
@immutable
class VocaGlass extends ThemeExtension<VocaGlass> {
  const VocaGlass({
    required this.tint,
    required this.highlight,
    required this.borderTop,
    required this.borderBottom,
    required this.blurSigma,
    required this.radius,
    required this.shadows,
  });

  /// The translucent fill.
  final Color tint;

  /// The lit top face, fading to nothing partway down.
  final Color highlight;

  /// The bright rim, where light enters.
  final Color borderTop;

  /// The dim rim, where it leaves.
  final Color borderBottom;

  /// Backdrop blur. Moderate: heavy blur is expensive on mid-range Android and flattens
  /// the field behind into grey mush, which removes the very thing glass is showing.
  final double blurSigma;

  final double radius;

  /// Soft, wide, low-opacity. Depth comes from softness, not darkness.
  final List<BoxShadow> shadows;

  static const light = VocaGlass(
    tint: Color(0xA6FFFFFF),
    highlight: Color(0x66FFFFFF),
    borderTop: Color(0xB3FFFFFF),
    borderBottom: Color(0x1F5B5BF7),
    blurSigma: 24,
    radius: VocaRadius.xlarge,
    shadows: [
      BoxShadow(
        color: Color(0x1A2B2B60),
        blurRadius: 40,
        spreadRadius: -6,
        offset: Offset(0, 18),
      ),
      BoxShadow(
        color: Color(0x0D2B2B60),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );

  static const dark = VocaGlass(
    tint: Color(0x8C1B212C),
    highlight: Color(0x1AFFFFFF),
    borderTop: Color(0x3DFFFFFF),
    borderBottom: Color(0x14FFFFFF),
    blurSigma: 24,
    radius: VocaRadius.xlarge,
    shadows: [
      BoxShadow(
        color: Color(0x80000000),
        blurRadius: 40,
        spreadRadius: -6,
        offset: Offset(0, 18),
      ),
    ],
  );

  @override
  VocaGlass copyWith({
    Color? tint,
    Color? highlight,
    Color? borderTop,
    Color? borderBottom,
    double? blurSigma,
    double? radius,
    List<BoxShadow>? shadows,
  }) {
    return VocaGlass(
      tint: tint ?? this.tint,
      highlight: highlight ?? this.highlight,
      borderTop: borderTop ?? this.borderTop,
      borderBottom: borderBottom ?? this.borderBottom,
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
      highlight: Color.lerp(highlight, other.highlight, t)!,
      borderTop: Color.lerp(borderTop, other.borderTop, t)!,
      borderBottom: Color.lerp(borderBottom, other.borderBottom, t)!,
      blurSigma: _lerpDouble(blurSigma, other.blurSigma, t),
      radius: _lerpDouble(radius, other.radius, t),
      shadows: BoxShadow.lerpList(shadows, other.shadows, t) ?? shadows,
    );
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

extension VocaGlassX on BuildContext {
  VocaGlass get vocaGlass =>
      Theme.of(this).extension<VocaGlass>() ?? VocaGlass.light;
}
