/// Semantic colour tokens.
///
/// Widgets read colours by MEANING, never by value: `colors.textSecondary`, not a hex
/// literal. That is what makes dark mode a second token set rather than an audit of every
/// widget, and it is why a raw `Color(0xFF...)` outside this file is a bug.
///
/// Exposed as a [ThemeExtension] so `Theme.of(context)` resolves the right set for the
/// active brightness automatically.
library;

import 'package:flutter/material.dart';

/// The raw palette. Private on purpose: nothing outside this file may reference a value
/// directly, because a value has no meaning and cannot be themed.
abstract final class _Palette {
  // Indigo accent.
  static const indigo50 = Color(0xFFEEEEFE);
  static const indigo500 = Color(0xFF5B5BF7);
  static const indigo600 = Color(0xFF4A4AE0);

  // Neutrals.
  static const white = Color(0xFFFFFFFF);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray300 = Color(0xFFD1D5DB);
  static const gray600 = Color(0xFF4B5563);
  static const gray700 = Color(0xFF374151);
  static const gray900 = Color(0xFF111827);
  static const gray950 = Color(0xFF0B0F17);

  // Status.
  //
  // These tokens are used as FOREGROUND: status icons and badge text. The vivid
  // 500-weights (#22C55E, #F59E0B) read beautifully as fills but fall well below 3:1 on
  // a white card, so the darker weights are the semantic colours and the 100-weights
  // remain the muted fills behind them.
  static const green600 = Color(0xFF16A34A);
  static const green100 = Color(0xFFDCFCE7);
  static const green900 = Color(0xFF14532D);
  static const amber700 = Color(0xFFB45309);
  static const amber100 = Color(0xFFFEF3C7);
  static const amber900 = Color(0xFF78350F);
  static const red600 = Color(0xFFDC2626);
  static const red100 = Color(0xFFFEE2E2);
  static const red800 = Color(0xFF991B1B);
  static const red300 = Color(0xFFFCA5A5);
  static const green300 = Color(0xFF86EFAC);
  static const amber300 = Color(0xFFFCD34D);
}

/// The semantic colour set for one brightness.
@immutable
class VocaColors extends ThemeExtension<VocaColors> {
  const VocaColors({
    required this.primary,
    required this.onPrimary,
    required this.primaryPressed,
    required this.primaryMuted,
    required this.onPrimaryMuted,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.border,
    required this.borderStrong,
    required this.success,
    required this.successMuted,
    required this.onSuccessMuted,
    required this.warning,
    required this.warningMuted,
    required this.onWarningMuted,
    required this.error,
    required this.errorMuted,
    required this.onErrorMuted,
    required this.overlay,
  });

  /// Brand accent. Primary actions, focus, selection.
  final Color primary;

  /// Content placed on [primary]. Must clear 4.5:1 against it.
  final Color onPrimary;

  /// [primary] while a control is held. A visible press state is a usability
  /// requirement, not decoration.
  final Color primaryPressed;

  /// A quiet wash of the accent, for selected rows and subtle highlights.
  final Color primaryMuted;

  /// Text and icons that sit on a brand-tinted surface, such as a sound chip or the active
  /// tab. Brand colour on a brand tint loses contrast twice over, so this is a deeper shade
  /// in light and a paler one in dark, keeping the hue while clearing 4.5:1.
  final Color onPrimaryMuted;

  /// The page behind everything.
  final Color background;

  /// A resting surface on top of [background]: cards, sheets.
  final Color surface;

  /// A surface that should read as lifted: menus, dialogs, sticky bars.
  final Color surfaceElevated;

  /// Body and heading text. The highest-contrast token.
  final Color textPrimary;

  /// Supporting text. Meets 4.5:1 on [background] and [surface]; never used for
  /// anything a person must be able to read at a glance under pressure.
  final Color textSecondary;

  /// Text in a disabled control. Deliberately below body contrast, because disabled
  /// content must read as unavailable.
  final Color textDisabled;

  /// Hairline separation between elements.
  final Color border;

  /// A border that must be seen: input outlines, focused edges.
  final Color borderStrong;

  /// Status colours, used as FOREGROUND on a surface: icons and badge text.
  final Color success;
  final Color warning;
  final Color error;

  /// Quiet fills behind a status foreground.
  final Color successMuted;
  final Color warningMuted;
  final Color errorMuted;

  /// Text placed on the matching muted fill. Each clears 4.5:1 against it, which the
  /// status colour itself does not always do.
  final Color onSuccessMuted;
  final Color onWarningMuted;
  final Color onErrorMuted;

  /// Scrim behind a modal surface.
  final Color overlay;

  /// Light theme. The default; Voca's direction is bright, calm and spacious.
  static const light = VocaColors(
    primary: _Palette.indigo500,
    onPrimary: _Palette.white,
    primaryPressed: _Palette.indigo600,
    primaryMuted: _Palette.indigo50,
    onPrimaryMuted: Color(0xFF4338CA),
    // A pale mint rather than near-white: white glass needs something to sit on, and on
    // a white page it disappears. The green sits with the teal corner light on cards.
    background: Color(0xFFEDF5F1),
    surface: _Palette.white,
    surfaceElevated: _Palette.white,
    textPrimary: _Palette.gray900,
    // Darker than the usual gray-500: secondary text sits on the liquid and on glass
    // over it, and gray-500 drops to 2.5:1 on a body of the liquid. This clears 4.5:1 on
    // every colour the liquid can put behind it (contrast_test).
    textSecondary: _Palette.gray700,
    textDisabled: _Palette.gray300,
    border: _Palette.gray200,
    borderStrong: _Palette.gray300,
    success: _Palette.green600,
    successMuted: _Palette.green100,
    onSuccessMuted: _Palette.green900,
    warning: _Palette.amber700,
    warningMuted: _Palette.amber100,
    onWarningMuted: _Palette.amber900,
    error: _Palette.red600,
    errorMuted: _Palette.red100,
    onErrorMuted: _Palette.red800,
    overlay: Color(0x66111827),
  );

  /// Dark theme.
  ///
  /// Not visually designed yet, but complete and coherent, so the app can run in dark
  /// mode today without unreadable text. Refining it is a design task; the token set it
  /// fills in will not change.
  static const dark = VocaColors(
    primary: Color(0xFF7C7CFF),
    onPrimary: _Palette.gray950,
    primaryPressed: Color(0xFF7373F0),
    primaryMuted: Color(0xFF1E1E3A),
    onPrimaryMuted: Color(0xFFB4B4FF),
    background: _Palette.gray950,
    surface: Color(0xFF141922),
    surfaceElevated: Color(0xFF1B212C),
    textPrimary: Color(0xFFF3F4F6),
    // Lighter than gray-400 for the same reason as in light: over the liquid, gray-400
    // falls to about 3:1.
    textSecondary: Color(0xFFCBD0D8),
    textDisabled: _Palette.gray600,
    border: Color(0xFF232A36),
    borderStrong: Color(0xFF323B4A),
    success: _Palette.green300,
    successMuted: Color(0xFF0F2A1A),
    onSuccessMuted: _Palette.green300,
    warning: _Palette.amber300,
    warningMuted: Color(0xFF2A1F08),
    onWarningMuted: _Palette.amber300,
    error: _Palette.red300,
    errorMuted: Color(0xFF2A1114),
    onErrorMuted: _Palette.red300,
    overlay: Color(0x99000000),
  );

  @override
  VocaColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? primaryPressed,
    Color? primaryMuted,
    Color? onPrimaryMuted,
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? border,
    Color? borderStrong,
    Color? success,
    Color? successMuted,
    Color? onSuccessMuted,
    Color? warning,
    Color? warningMuted,
    Color? onWarningMuted,
    Color? error,
    Color? errorMuted,
    Color? onErrorMuted,
    Color? overlay,
  }) {
    return VocaColors(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      primaryMuted: primaryMuted ?? this.primaryMuted,
      onPrimaryMuted: onPrimaryMuted ?? this.onPrimaryMuted,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      success: success ?? this.success,
      successMuted: successMuted ?? this.successMuted,
      onSuccessMuted: onSuccessMuted ?? this.onSuccessMuted,
      warning: warning ?? this.warning,
      warningMuted: warningMuted ?? this.warningMuted,
      onWarningMuted: onWarningMuted ?? this.onWarningMuted,
      error: error ?? this.error,
      errorMuted: errorMuted ?? this.errorMuted,
      onErrorMuted: onErrorMuted ?? this.onErrorMuted,
      overlay: overlay ?? this.overlay,
    );
  }

  @override
  VocaColors lerp(covariant VocaColors? other, double t) {
    if (other == null) return this;
    return VocaColors(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primaryPressed: Color.lerp(primaryPressed, other.primaryPressed, t)!,
      primaryMuted: Color.lerp(primaryMuted, other.primaryMuted, t)!,
      onPrimaryMuted: Color.lerp(onPrimaryMuted, other.onPrimaryMuted, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      success: Color.lerp(success, other.success, t)!,
      successMuted: Color.lerp(successMuted, other.successMuted, t)!,
      onSuccessMuted: Color.lerp(onSuccessMuted, other.onSuccessMuted, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningMuted: Color.lerp(warningMuted, other.warningMuted, t)!,
      onWarningMuted: Color.lerp(onWarningMuted, other.onWarningMuted, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorMuted: Color.lerp(errorMuted, other.errorMuted, t)!,
      onErrorMuted: Color.lerp(onErrorMuted, other.onErrorMuted, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
    );
  }
}

/// Reads the semantic colours for the current theme.
///
/// `context.vocaColors.textSecondary` is the intended way to reach a colour.
extension VocaColorsX on BuildContext {
  VocaColors get vocaColors =>
      Theme.of(this).extension<VocaColors>() ?? VocaColors.light;
}
