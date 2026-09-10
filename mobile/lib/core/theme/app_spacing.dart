/// Spacing scale.
///
/// One scale, used everywhere. A layout that needs a value not on this scale is usually
/// a layout that has drifted, so reach for the nearest token before inventing a number.
///
/// The scale is deliberately coarse at the top: fine control belongs near content,
/// generous rhythm belongs between sections. Voca's visual direction is spacious, and
/// spacing is the main instrument for that.
library;

abstract final class VocaSpacing {
  /// 4 — hairline separation, icon to label.
  static const double xxs = 4;

  /// 8 — tight grouping inside a control.
  static const double xs = 8;

  /// 12 — related elements.
  static const double sm = 12;

  /// 16 — the default gap, and the default screen inset on small phones.
  static const double md = 16;

  /// 20 — comfortable screen inset.
  static const double lg = 20;

  /// 24 — between distinct blocks.
  static const double xl = 24;

  /// 32 — between sections.
  static const double xxl = 32;

  /// 40 — around a focal element.
  static const double xxxl = 40;

  /// 48 — top of a screen with a single subject.
  static const double huge = 48;
}
