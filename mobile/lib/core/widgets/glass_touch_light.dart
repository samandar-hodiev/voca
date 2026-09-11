/// The light a finger leaves in Liquid Glass.
///
/// Pressing a glass control makes it glow softly from the point of contact, and the glow
/// fades once the finger lifts. It is how iOS makes glass feel like a material under the
/// hand, and it replaces the Material ripple, which has no place on glass.
library;

import 'package:flutter/material.dart';

class GlassTouchLight extends StatefulWidget {
  const GlassTouchLight({
    super.key,
    required this.child,
    required this.borderRadius,
    this.enabled = true,
  });

  final Widget child;

  /// The shape the light is kept inside.
  final BorderRadius borderRadius;
  final bool enabled;

  @override
  State<GlassTouchLight> createState() => _GlassTouchLightState();
}

class _GlassTouchLightState extends State<GlassTouchLight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _light = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  Offset? _point;

  @override
  void dispose() {
    _light.dispose();
    super.dispose();
  }

  void _down(PointerDownEvent event) {
    if (!widget.enabled) return;
    setState(() => _point = event.localPosition);
    _light.value = 1;
  }

  void _up(PointerEvent _) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _light.value = 0;
    } else {
      _light.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Listener(
      onPointerDown: _down,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: widget.borderRadius,
                child: AnimatedBuilder(
                  animation: _light,
                  builder: (context, _) => CustomPaint(
                    painter: _TouchGlow(
                      point: _point,
                      strength: _light.value * (dark ? 0.16 : 0.35),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TouchGlow extends CustomPainter {
  const _TouchGlow({required this.point, required this.strength});

  final Offset? point;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final p = point;
    if (p == null || strength <= 0 || size.isEmpty) return;
    final r = size.longestSide * 0.6;
    canvas.drawCircle(
      p,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: strength),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: p, radius: r)),
    );
  }

  @override
  bool shouldRepaint(_TouchGlow old) =>
      old.point != point || old.strength != strength;
}
