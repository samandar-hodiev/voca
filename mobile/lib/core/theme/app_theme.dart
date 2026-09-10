/// Assembles the Material themes from Voca's tokens.
///
/// This is the only file that builds [ThemeData]. Widgets read tokens through the theme
/// extensions rather than importing palettes directly, so a visual change is contained to
/// `core/theme` (ARCHITECTURE.md 4.6, 44).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_glass.dart';
import 'app_radius.dart';
import 'app_typography.dart';

abstract final class VocaTheme {
  static ThemeData light() => _build(VocaColors.light, VocaGlass.light, Brightness.light);

  static ThemeData dark() => _build(VocaColors.dark, VocaGlass.dark, Brightness.dark);

  static ThemeData _build(VocaColors c, VocaGlass g, Brightness brightness) {
    final textTheme = VocaTypography.textTheme().apply(
      bodyColor: c.textPrimary,
      displayColor: c.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      textTheme: textTheme,

      colorScheme: ColorScheme.fromSeed(
        seedColor: c.primary,
        brightness: brightness,
      ).copyWith(
        primary: c.primary,
        onPrimary: c.onPrimary,
        surface: c.surface,
        onSurface: c.textPrimary,
        error: c.error,
      ),

      // Voca's own tokens travel with the theme, so dark mode resolves automatically.
      extensions: <ThemeExtension<dynamic>>[c, g],

      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: c.textPrimary),
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),

      dividerTheme: DividerThemeData(
        color: c.border,
        thickness: 1,
        space: 1,
      ),

      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: VocaRadius.largeAll),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: textTheme.bodyLarge?.copyWith(color: c.textSecondary),
        border: OutlineInputBorder(
          borderRadius: VocaRadius.mediumAll,
          borderSide: BorderSide(color: c.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: VocaRadius.mediumAll,
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: VocaRadius.mediumAll,
          borderSide: BorderSide(color: c.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: VocaRadius.mediumAll,
          borderSide: BorderSide(color: c.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: VocaRadius.mediumAll,
          borderSide: BorderSide(color: c.error, width: 2),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.border,
        circularTrackColor: c.border,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surfaceElevated,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: VocaRadius.mediumAll),
      ),

      splashFactory: InkSparkle.splashFactory,
    );
  }
}
