/// Motion tokens.
///
/// Motion supports the interface; it does not become the interface. Durations are short,
/// curves are gentle, and nothing loops without a reason.
///
/// Pronunciation feedback will need stronger, longer motion than anything here. That is
/// why [emphasized] and [expressive] exist as named tokens rather than being invented
/// later at the call site: the scale has room to grow without becoming inconsistent.
///
/// Every animated widget in the app should honour [MediaQuery.disableAnimationsOf], which
/// carries the platform's reduce-motion accessibility setting.
library;

import 'package:flutter/widgets.dart';

abstract final class VocaMotion {
  /// 120ms — state change on a control the finger is already touching.
  static const Duration instant = Duration(milliseconds: 120);

  /// 200ms — the default. Fades, small scales, colour changes.
  static const Duration quick = Duration(milliseconds: 200);

  /// 320ms — surfaces entering or leaving, route transitions.
  static const Duration standard = Duration(milliseconds: 320);

  /// 480ms — a deliberate, noticeable movement. Reserved for feedback moments.
  static const Duration emphasized = Duration(milliseconds: 480);

  /// 720ms — reserved for pronunciation result reveals. Unused in this foundation.
  static const Duration expressive = Duration(milliseconds: 720);

  /// Default easing. Decelerating, so movement settles rather than stops.
  static const Curve standardCurve = Curves.easeOutCubic;

  /// Entering the screen.
  static const Curve enterCurve = Curves.easeOutCubic;

  /// Leaving the screen: faster out than in, so exits do not feel sluggish.
  static const Curve exitCurve = Curves.easeInCubic;

  /// A gentle overshoot for a moment that should feel alive. Use sparingly; the visual
  /// direction is calm, and bounce reads as playful.
  static const Curve emphasizedCurve = Curves.easeOutBack;

  /// Returns [duration], or [Duration.zero] when the viewer has asked for reduced motion.
  ///
  /// Accessibility outranks visual effect, so every animation goes through here.
  static Duration respectReducedMotion(BuildContext context, Duration duration) {
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
  }
}
