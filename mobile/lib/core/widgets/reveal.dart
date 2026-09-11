/// Fades and lifts content in the first time it appears.
///
/// Cards on a dashboard arriving together look like a page loading; arriving a few
/// milliseconds apart look like a page being laid out. [index] sets the stagger. The
/// movement is small and runs once: nothing here loops, and with reduced motion content
/// simply appears.
library;

import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.child, this.index = 0});

  final Widget child;

  /// Position in the sequence. Each step adds a short delay, capped so a long list does
  /// not keep the last card waiting.
  final int index;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    final delayMs = (index.clamp(0, 6)) * 50;
    final total = VocaMotion.standard.inMilliseconds + delayMs;
    final start = delayMs / total;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(start, 1, curve: VocaMotion.enterCurve),
      builder: (context, t, inner) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 12),
          child: inner,
        ),
      ),
      child: child,
    );
  }
}
