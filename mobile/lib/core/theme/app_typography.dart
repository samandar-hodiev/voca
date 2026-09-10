/// Typography.
///
/// The system font is used on purpose: SF Pro on Apple platforms and Roboto on Android,
/// via [TextTheme] defaults. It renders Uzbek Latin diacritics correctly, needs no
/// download, adds nothing to the bundle, and matches what people already read on their
/// device. A custom brand face can be introduced later by changing this file alone.
///
/// Sizes are tokens. A widget that hardcodes `fontSize:` has stepped outside the system.
library;

import 'package:flutter/material.dart';

abstract final class VocaTypography {
  // Sizes.
  static const double displaySize = 34;
  static const double headlineSize = 26;
  static const double titleSize = 20;
  static const double subtitleSize = 17;
  static const double bodySize = 16;
  static const double bodySmallSize = 15;
  static const double labelSize = 14;
  static const double captionSize = 12;

  // Line heights, expressed as a multiple of font size. Generous, because the visual
  // direction is spacious and long-form Uzbek text needs room.
  static const double tightHeight = 1.15;
  static const double standardHeight = 1.35;
  static const double relaxedHeight = 1.5;

  /// Builds the text theme for a brightness.
  ///
  /// Every style leaves [TextStyle.color] unset so it inherits from the theme. Colour is
  /// a separate token axis; baking it in here would break dark mode.
  static TextTheme textTheme() {
    return const TextTheme(
      // Display — one per screen at most. The subject of the page.
      displayLarge: TextStyle(
        fontSize: displaySize,
        height: tightHeight,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      // Headline — section openers.
      headlineMedium: TextStyle(
        fontSize: headlineSize,
        height: tightHeight,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      // Title — card and group headings.
      titleLarge: TextStyle(
        fontSize: titleSize,
        height: standardHeight,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      // Subtitle.
      titleMedium: TextStyle(
        fontSize: subtitleSize,
        height: standardHeight,
        fontWeight: FontWeight.w600,
      ),
      // Body — the default reading style.
      bodyLarge: TextStyle(
        fontSize: bodySize,
        height: relaxedHeight,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        fontSize: bodySmallSize,
        height: relaxedHeight,
        fontWeight: FontWeight.w400,
      ),
      // Label — buttons and form labels.
      labelLarge: TextStyle(
        fontSize: labelSize,
        height: standardHeight,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      // Caption — metadata, timestamps, helper text.
      bodySmall: TextStyle(
        fontSize: captionSize,
        height: standardHeight,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      ),
    );
  }
}

/// Convenience access to the semantic text styles.
///
/// `context.vocaText.display` reads better at a call site than digging through
/// `Theme.of(context).textTheme.displayLarge!`.
extension VocaTextX on BuildContext {
  VocaTextStyles get vocaText => VocaTextStyles(Theme.of(this).textTheme);
}

/// Semantic names over Material's slot names.
@immutable
class VocaTextStyles {
  const VocaTextStyles(this._t);

  final TextTheme _t;

  TextStyle get display => _t.displayLarge!;
  TextStyle get headline => _t.headlineMedium!;
  TextStyle get title => _t.titleLarge!;
  TextStyle get subtitle => _t.titleMedium!;
  TextStyle get body => _t.bodyLarge!;
  TextStyle get bodyMedium => _t.bodyMedium!;
  TextStyle get label => _t.labelLarge!;
  TextStyle get caption => _t.bodySmall!;
}
