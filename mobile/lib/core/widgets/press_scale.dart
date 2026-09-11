/// Gives any tappable surface a small, quick press response.
///
/// A card that does nothing when a finger lands on it feels dead even when the tap works.
/// The response is a slight shrink, fast enough to feel rather than watch.
library;

import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Announced to screen readers. Required in practice for anything without a visible
  /// label of its own.
  final String? semanticLabel;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: VocaMotion.respectReducedMotion(
            context,
            VocaMotion.instant,
          ),
          curve: VocaMotion.standardCurve,
          child: widget.child,
        ),
      ),
    );
  }
}
