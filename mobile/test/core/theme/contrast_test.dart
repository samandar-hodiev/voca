// Accessibility: colour contrast.
//
// Glass and soft palettes are exactly where contrast quietly fails, so the token set is
// verified rather than trusted. WCAG AA requires 4.5:1 for body text and 3:1 for large
// text and meaningful UI boundaries.
//
// A failure here is a design bug, not a test bug: readability outranks the visual effect
// (ARCHITECTURE.md 44, PART 19 of the foundation task).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca/core/theme/app_colors.dart';
import 'package:voca/core/theme/app_glass.dart';
import 'package:voca/core/widgets/app_badge.dart';
import 'package:voca/core/widgets/glass_surface.dart';
import 'package:voca/core/widgets/liquid_background.dart';
import 'package:voca/core/widgets/liquid_bottom_bar.dart';
import 'package:voca/core/widgets/liquid_drop.dart';

/// Relative luminance per WCAG 2.1.
double _luminance(Color c) {
  double channel(double v) {
    return v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double contrastRatio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  const aaBody = 4.5;
  const aaLarge = 3.0;

  for (final (name, colors) in <(String, VocaColors)>[
    ('light', VocaColors.light),
    ('dark', VocaColors.dark),
  ]) {
    group('$name theme', () {
      test('primary text meets AA on background and surface', () {
        expect(
          contrastRatio(colors.textPrimary, colors.background),
          greaterThanOrEqualTo(aaBody),
          reason: 'body text on the page background',
        );
        expect(
          contrastRatio(colors.textPrimary, colors.surface),
          greaterThanOrEqualTo(aaBody),
          reason: 'body text on a card',
        );
      });

      // textSecondary carries real content, not decoration, so it must clear the body
      // threshold too.
      test('secondary text meets AA on background and surface', () {
        expect(
          contrastRatio(colors.textSecondary, colors.background),
          greaterThanOrEqualTo(aaBody),
        );
        expect(
          contrastRatio(colors.textSecondary, colors.surface),
          greaterThanOrEqualTo(aaBody),
        );
      });

      test('primary button label meets AA against its fill', () {
        expect(
          contrastRatio(colors.onPrimary, colors.primary),
          greaterThanOrEqualTo(aaBody),
        );
      });

      test('pressed primary keeps its label readable', () {
        expect(
          contrastRatio(colors.onPrimary, colors.primaryPressed),
          greaterThanOrEqualTo(aaBody),
        );
      });

      test('status colours are distinguishable from the surface', () {
        for (final (label, color) in [
          ('success', colors.success),
          ('warning', colors.warning),
          ('error', colors.error),
        ]) {
          expect(
            contrastRatio(color, colors.surface),
            greaterThanOrEqualTo(aaLarge),
            reason: '$label must be visible against a card',
          );
        }
      });

      test('badge text meets AA on its muted background', () {
        expect(
          contrastRatio(colors.onSuccessMuted, colors.successMuted),
          greaterThanOrEqualTo(aaBody),
          reason: 'success badge',
        );
        expect(
          contrastRatio(colors.onErrorMuted, colors.errorMuted),
          greaterThanOrEqualTo(aaBody),
          reason: 'error badge',
        );
      });
    });
  }

  // Disabled content must read as unavailable, which means it should NOT reach body
  // contrast. This asserts the intent rather than leaving it to chance.
  test('disabled text is deliberately below body contrast', () {
    expect(
      contrastRatio(VocaColors.light.textDisabled, VocaColors.light.background),
      lessThan(aaBody),
    );
  });

  // Surfaces added by the signed-in shell. Brand text on a brand-tinted chip loses
  // contrast twice over, once from the tint and once from sharing a hue, so these pairs
  // are checked outright rather than assumed from the ones above.
  for (final (name, colors) in <(String, VocaColors)>[
    ('light', VocaColors.light),
    ('dark', VocaColors.dark),
  ]) {
    group('$name theme, signed-in surfaces', () {
      for (final (what, alpha) in [('sound symbol chip', 0.12)]) {
        test('text on the $what stays readable', () {
          for (final (where, base) in [
            ('surface', colors.surface),
            ('background', colors.background),
          ]) {
            final tint = Color.alphaBlend(
              colors.primary.withValues(alpha: alpha),
              base,
            );
            final ratio = contrastRatio(colors.onPrimaryMuted, tint);
            expect(
              ratio,
              greaterThanOrEqualTo(aaBody),
              reason: '$what over $where is ${ratio.toStringAsFixed(2)}:1',
            );
          }
        });
      }

      // The reason the token exists: on a brand tint the muted token always reads better
      // than plain brand text would.
      test('the muted brand token beats plain brand text on a brand tint', () {
        final tint = Color.alphaBlend(
          colors.primary.withValues(alpha: 0.14),
          colors.surface,
        );
        expect(
          contrastRatio(colors.onPrimaryMuted, tint),
          greaterThan(contrastRatio(colors.primary, tint)),
        );
      });

      test('captions stay readable on the elevated score card', () {
        final ratio = contrastRatio(
          colors.textSecondary,
          colors.surfaceElevated,
        );
        expect(
          ratio,
          greaterThanOrEqualTo(aaBody),
          reason:
              'caption on elevated surface is ${ratio.toStringAsFixed(2)}:1',
        );
      });
    });
  }

  // The background behind every screen. Text sits straight on it (onboarding, the section
  // titles in the tabs) and on glass over it, so text is checked where each colour field
  // is strongest and where all of them stack. Glass sees the background through its
  // saturation boost, so that is applied too. The numbers come from the widgets.
  for (final (name, colors, glass, brightness)
      in <(String, VocaColors, VocaGlass, Brightness)>[
        ('light', VocaColors.light, VocaGlass.light, Brightness.light),
        ('dark', VocaColors.dark, VocaGlass.dark, Brightness.dark),
      ]) {
    group('$name theme, over the background', () {
      final fields = LiquidBackground.fields(colors, brightness);
      final backdrops = <(String, Color)>[
        for (final (i, (color, _, _)) in fields.indexed)
          ('centre of field $i', Color.alphaBlend(color, colors.background)),
        (
          'all fields stacked',
          fields.fold(
            colors.background,
            (base, field) => Color.alphaBlend(field.$1, base),
          ),
        ),
      ];

      void expectReadable(
        String what,
        Color text,
        Color Function(Color backdrop) surface,
      ) {
        for (final (where, backdrop) in backdrops) {
          final ratio = contrastRatio(text, surface(backdrop));
          expect(
            ratio,
            greaterThanOrEqualTo(aaBody),
            reason: '$what over the $where is ${ratio.toStringAsFixed(2)}:1',
          );
        }
      }

      Color throughGlass(Color tint, Color b) =>
          Color.alphaBlend(tint, GlassSurface.saturate(b));

      test('text straight on the background meets AA', () {
        expectReadable('primary text', colors.textPrimary, (b) => b);
        expectReadable('secondary text', colors.textSecondary, (b) => b);
      });

      test('text on a glass card meets AA', () {
        Color card(Color b) => throughGlass(glass.tint, b);
        expectReadable('primary text', colors.textPrimary, card);
        expectReadable('secondary text', colors.textSecondary, card);
      });

      test('text in a clear glass well meets AA', () {
        Color well(Color b) => Color.alphaBlend(GlassBead.fill(brightness), b);
        expectReadable('primary text', colors.textPrimary, well);
        expectReadable('secondary text', colors.textSecondary, well);
      });

      // The label sits on the colour or deeper: the light at the top has faded by the
      // label's band, and below it the liquid only darkens. In dark mode the label is
      // dark, so the deepest point, the bottom edge, is the one to check.
      test('primary button label on its liquid meets AA', () {
        expect(
          LiquidDrop.colourStop,
          lessThanOrEqualTo(LiquidDrop.labelBandTop),
        );
        final teal = LiquidDrop.brandTeal(brightness);
        for (final fill in [
          colors.primary,
          Color.lerp(colors.primary, teal, 0.9)!,
        ]) {
          final worst = brightness == Brightness.dark
              ? Color.lerp(fill, Colors.black, LiquidDrop.shadeDark)!
              : fill;
          final ratio = contrastRatio(colors.onPrimary, worst);
          expect(
            ratio,
            greaterThanOrEqualTo(aaBody),
            reason: 'label on the button is ${ratio.toStringAsFixed(2)}:1',
          );
        }
      });

      test('badge text on its half-tone glass meets AA', () {
        for (final (tone, fill, text) in [
          ('neutral', colors.border, colors.textSecondary),
          ('primary', colors.primaryMuted, colors.onPrimaryMuted),
          ('success', colors.successMuted, colors.onSuccessMuted),
          ('warning', colors.warningMuted, colors.onWarningMuted),
          ('error', colors.errorMuted, colors.onErrorMuted),
        ]) {
          expectReadable(
            '$tone badge',
            text,
            (b) => Color.alphaBlend(
              fill.withValues(alpha: AppBadge.tintAlpha),
              Color.alphaBlend(
                GlassBead.fill(brightness),
                throughGlass(glass.tint, b),
              ),
            ),
          );
        }
      });

      test('tab labels on the clear bar meet AA', () {
        final alpha = brightness == Brightness.dark
            ? LiquidBottomBar.darkGlassAlpha
            : LiquidBottomBar.lightGlassAlpha;
        Color bar(Color b) =>
            throughGlass(glass.tint.withValues(alpha: alpha), b);
        Color lens(Color b) => Color.alphaBlend(
          LiquidBottomBar.lensTopLight(brightness),
          Color.alphaBlend(LiquidBottomBar.lensFill(brightness), bar(b)),
        );
        expectReadable('inactive label', colors.textSecondary, bar);
        expectReadable('selected label on the pill', colors.textPrimary, lens);
      });
    });
  }
}
