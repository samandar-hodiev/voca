/// Glass surface primitives.
///
/// Two widgets, not a family: [GlassSurface] is the primitive and [GlassCard] is the
/// padded card everything else should reach for.
///
/// The look follows Apple's Liquid Glass and a reference card the product owner chose,
/// dark smoked glass with light pooling at two corners:
///
/// * What shows through is blurred and made more saturated, so colour glows through
///   instead of turning grey.
/// * The tint is thin in light and a near-black smoke in dark.
/// * The rim is a dim hairline. On cards, light pools at two opposite corners, top-right
///   and bottom-left, and spills a little past the edge. That corner light is what makes
///   a card read as a lit piece of glass rather than a box with a border.
/// * Light gathers just inside the rim, the lensing that makes it liquid.
/// * No glints, blobs or coloured fills. Those turn glass into a cartoon of glass.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_glass.dart';
import '../theme/app_spacing.dart';

/// A translucent, blurred, softly lit surface.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.blur = true,
    this.showShadow = true,
    this.tint,
    this.borderWidth = 1,
    this.edgeGlow = true,
    this.blurSigma,
    this.highlight,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  /// Overrides the fill. Null uses the theme's tint.
  final Color? tint;

  /// Rim thickness.
  final double borderWidth;

  /// Whether to blur what is behind. Turn it off inside long scrolling lists: many
  /// simultaneous [BackdropFilter]s are the fastest way to make a mid-range Android
  /// device stutter.
  final bool blur;

  final bool showShadow;

  /// Whether light pools at the top-right and bottom-left corners. On for cards, sheets
  /// and dialogs; off for controls and the tab bar, whose rim is a plain hairline, so a
  /// screen has one kind of lit object rather than a dozen.
  final bool edgeGlow;

  /// Overrides how strongly what is behind is blurred. The tab bar blurs less, so what
  /// passes under it stays recognisable and the bar reads as clear glass.
  final double? blurSigma;

  /// Overrides the soft light across the top of the pane.
  final Color? highlight;

  /// The corner light, per theme: a teal between the brand indigo and the green in the
  /// background, as in the reference.
  static Color cornerLight(Brightness brightness) =>
      brightness == Brightness.dark
      ? const Color(0xE64FE3D0)
      : const Color(0x8C14B8A6);

  /// The saturation boost applied to what is seen through the pane (1.8), as a colour
  /// matrix that keeps luminance where it was.
  static const saturation = <double>[
    1.62992, -0.57216, -0.05776, 0, 0, //
    -0.17008, 1.22784, -0.05776, 0, 0, //
    -0.17008, -0.57216, 1.74224, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  /// [color] as it looks through the pane's saturation boost. Public so the contrast test
  /// uses exactly what the pane does.
  @visibleForTesting
  static Color saturate(Color color) {
    double channel(int row) =>
        (saturation[row * 5] * color.r +
                saturation[row * 5 + 1] * color.g +
                saturation[row * 5 + 2] * color.b)
            .clamp(0.0, 1.0);
    return Color.from(
      alpha: color.a,
      red: channel(0),
      green: channel(1),
      blue: channel(2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.vocaGlass;
    final brightness = Theme.of(context).brightness;
    final radius = borderRadius ?? BorderRadius.circular(glass.radius);

    // The pane: a thin tint, soft light fading down from the top edge, and light
    // gathering at the rim. Stacked decorations on purpose: BoxDecoration ignores
    // `color` the moment a `gradient` is set.
    Widget pane = DecoratedBox(
      decoration: BoxDecoration(
        color: tint ?? glass.tint,
        borderRadius: radius,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              highlight ?? glass.highlight,
              (highlight ?? glass.highlight).withValues(alpha: 0),
            ],
            stops: const [0, 0.5],
          ),
        ),
        child: CustomPaint(
          painter: _EdgeLens(
            borderRadius: radius,
            color: glass.borderTop.withValues(alpha: glass.borderTop.a * 0.55),
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(VocaSpacing.md),
            child: child,
          ),
        ),
      ),
    );

    if (blur) {
      pane = BackdropFilter(
        filter: ImageFilter.compose(
          outer: const ColorFilter.matrix(saturation),
          inner: ImageFilter.blur(
            sigmaX: blurSigma ?? glass.blurSigma,
            sigmaY: blurSigma ?? glass.blurSigma,
          ),
        ),
        child: pane,
      );
    }

    // The rim is painted over the clipped pane and is allowed past it, so the corner
    // light can spill over the edge. Passthrough, so a pane given a fixed size (a card
    // stretched to match its neighbour) fills it.
    final surface = Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        ClipRRect(borderRadius: radius, child: pane),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _RimLight(
                borderRadius: radius,
                width: borderWidth,
                top: glass.borderTop,
                bottom: glass.borderBottom,
                glow: edgeGlow ? cornerLight(brightness) : null,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _TopEdge(
                borderRadius: radius,
                inset: borderWidth + 0.5,
                color: glass.borderTop,
              ),
            ),
          ),
        ),
      ],
    );

    if (!showShadow) return surface;

    // The shadow is painted outside the pane only. Under translucent glass an ordinary
    // shadow shows through and turns the pane grey.
    return CustomPaint(
      painter: _OuterShadow(borderRadius: radius, shadows: glass.shadows),
      child: surface,
    );
  }
}

/// The rim: a dim hairline, a little brighter along the top, and when [glow] is given,
/// light pooling at the top-right and bottom-left corners with a soft bloom that spills
/// both ways across the edge.
class _RimLight extends CustomPainter {
  const _RimLight({
    required this.borderRadius,
    required this.width,
    required this.top,
    required this.bottom,
    required this.glow,
  });

  final BorderRadius borderRadius;
  final double width;
  final Color top;
  final Color bottom;
  final Color? glow;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final rim = borderRadius.toRRect(rect.deflate(width / 2));

    canvas.drawRRect(
      rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(rect),
    );

    final light = glow;
    if (light == null) return;
    // Scaled by the longer side, so a wide, short element gets light that runs a proper
    // way along its long edge instead of a dab at the corner.
    final reach = (size.longestSide * 0.34).clamp(70.0, 170.0);
    for (final corner in [rect.topRight, rect.bottomLeft]) {
      final area = Rect.fromCircle(center: corner, radius: reach);
      // The bloom: the same light, blurred, spilling across the edge.
      canvas.drawRRect(
        rim,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
          ..shader = RadialGradient(
            colors: [
              light.withValues(alpha: light.a * 0.55),
              light.withValues(alpha: 0),
            ],
          ).createShader(area),
      );
      // The lit hairline itself.
      canvas.drawRRect(
        rim,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 1.3
          ..shader = RadialGradient(
            colors: [light, light.withValues(alpha: 0)],
          ).createShader(area),
      );
    }
  }

  @override
  bool shouldRepaint(_RimLight old) =>
      old.borderRadius != borderRadius ||
      old.width != width ||
      old.top != top ||
      old.bottom != bottom ||
      old.glow != glow;
}

/// Light bending at the rim: a soft brightening just inside the edge that fades inward,
/// the way a thick piece of glass gathers light along its border. Kept to the edge,
/// inside the padding, so it never sits behind text.
class _EdgeLens extends CustomPainter {
  const _EdgeLens({required this.borderRadius, required this.color});

  final BorderRadius borderRadius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final pane = borderRadius.toRRect(Offset.zero & size);
    canvas
      ..save()
      ..clipRRect(pane)
      ..drawRRect(
        pane,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_EdgeLens old) =>
      old.borderRadius != borderRadius || old.color != color;
}

/// Paints [shadows] around a pane and never under it.
class _OuterShadow extends CustomPainter {
  const _OuterShadow({required this.borderRadius, required this.shadows});

  final BorderRadius borderRadius;
  final List<BoxShadow> shadows;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(rect.inflate(200)),
      Path()..addRRect(borderRadius.toRRect(rect)),
    );
    canvas
      ..save()
      ..clipPath(outside);
    for (final shadow in shadows) {
      canvas.drawRRect(
        borderRadius.toRRect(
          rect.shift(shadow.offset).inflate(shadow.spreadRadius),
        ),
        Paint()
          ..color = shadow.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurSigma),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OuterShadow old) =>
      old.borderRadius != borderRadius || old.shadows != shadows;
}

/// A second, fainter line just inside the rim along the top, gone by a third of the way
/// down. Two edges a hair apart are what give a pane its thickness.
class _TopEdge extends CustomPainter {
  const _TopEdge({
    required this.borderRadius,
    required this.inset,
    required this.color,
  });

  final BorderRadius borderRadius;
  final double inset;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (rect.width <= inset * 2 || rect.height <= inset * 2) return;
    canvas.drawRRect(
      borderRadius.toRRect(rect).deflate(inset),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: color.a * 0.5),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.3],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_TopEdge old) =>
      old.borderRadius != borderRadius ||
      old.inset != inset ||
      old.color != color;
}

/// The rim of a small glass control: two specular highlights, the brighter top-left where
/// the light comes from and a fainter one bottom-right, with the edge dimmer in between.
Gradient specularRim(Color bright, Color dim) {
  final soft = Color.lerp(dim, bright, 0.55)!;
  return SweepGradient(
    colors: [dim, soft, dim, bright, dim, dim],
    stops: const [0, 0.125, 0.375, 0.625, 0.875, 1],
  );
}

/// A border whose colour follows a gradient.
///
/// Flutter's [Border] takes a single colour per side, which cannot express a rim that
/// brightens toward the light. This paints the same inset ring with a shader instead.
class GradientBoxBorder extends BoxBorder {
  const GradientBoxBorder({required this.gradient, this.width = 1});

  final Gradient gradient;
  final double width;

  @override
  BorderSide get bottom => BorderSide.none;

  @override
  BorderSide get top => BorderSide.none;

  @override
  bool get isUniform => true;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final paint = Paint()
      ..strokeWidth = width
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke;

    // Inset by half the stroke so the ring sits inside the surface rather than straddling
    // its edge, which would soften the corner.
    final inner = rect.deflate(width / 2);

    if (borderRadius != null) {
      canvas.drawRRect(borderRadius.toRRect(inner), paint);
    } else {
      canvas.drawRect(inner, paint);
    }
  }

  @override
  ShapeBorder scale(double t) =>
      GradientBoxBorder(gradient: gradient, width: width * t);
}

/// A glass surface with card padding. The default choice for grouped content.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(VocaSpacing.lg),
    this.onTap,
    this.blur = true,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool blur;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final glass = context.vocaGlass;
    final radius = BorderRadius.circular(glass.radius);

    Widget card = GlassSurface(
      padding: padding,
      borderRadius: radius,
      blur: blur,
      child: child,
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: radius, child: card),
      );
    }

    if (semanticLabel != null) {
      card = Semantics(
        label: semanticLabel,
        button: onTap != null,
        child: card,
      );
    }

    return card;
  }
}
