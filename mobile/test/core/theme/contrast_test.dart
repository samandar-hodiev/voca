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

      // The reason the token exists: plain brand text would fail on the same tint.
      test('plain brand text would not have been enough', () {
        final tint = Color.alphaBlend(
          colors.primary.withValues(alpha: 0.14),
          colors.surface,
        );
        expect(contrastRatio(colors.primary, tint), lessThan(aaBody));
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
  // is strongest and where all of them stack. The numbers come from the widgets
  // themselves, so a stronger background that text cannot bear fails here.
  for (final (name, colors, glass, brightness)
      in <(String, VocaColors, VocaGlass, Brightness)>[
        ('light', VocaColors.light, VocaGlass.light, Brightness.light),
        ('dark', VocaColors.dark, VocaGlass.dark, Brightness.dark),
      ]) {
    group('$name theme, over the background', () {
      final fields = LiquidBackground.fields(colors);
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

      test('text straight on the background meets AA', () {
        expectReadable('primary text', colors.textPrimary, (b) => b);
        expectReadable('secondary text', colors.textSecondary, (b) => b);
      });

      // The tint over an unblurred field, plus the depth shade at the bottom of the pane,
      // is the worst case: the real card also blurs the field into the page around it.
      test('text on a glass card meets AA, down to its shaded bottom edge', () {
        Color card(Color b) => Color.alphaBlend(
          GlassSurface.depthShade(brightness),
          Color.alphaBlend(glass.tint, b),
        );
        expectReadable('primary text', colors.textPrimary, card);
        expectReadable('secondary text', colors.textSecondary, card);
      });

      // The label sits in the middle band of the liquid button. The lighter top of the
      // liquid and its highlight both have to be gone before that band starts, and the
      // lightest colour left behind the label must still carry it.
      test('primary button label on its liquid meets AA', () {
        expect(
          LiquidShine.highlightBottom,
          lessThanOrEqualTo(LiquidDrop.labelBandTop),
          reason: 'the highlight must end above the label',
        );
        final top = brightness == Brightness.dark
            ? LiquidDrop.topLightenDark
            : LiquidDrop.topLightenLight;
        final faded = (1 - LiquidDrop.labelBandTop / LiquidDrop.colourStop)
            .clamp(0.0, 1.0);
        final fill = Color.lerp(colors.primary, Colors.white, top * faded)!;
        final ratio = contrastRatio(colors.onPrimary, fill);
        expect(
          ratio,
          greaterThanOrEqualTo(aaBody),
          reason: 'label on the button is ${ratio.toStringAsFixed(2)}:1',
        );
      });

      test('tab labels on the clear bar meet AA', () {
        final alpha = brightness == Brightness.dark
            ? LiquidBottomBar.darkGlassAlpha
            : LiquidBottomBar.lightGlassAlpha;
        Color bar(Color b) =>
            Color.alphaBlend(glass.tint.withValues(alpha: alpha), b);
        expectReadable('active label', colors.textPrimary, bar);
        expectReadable('inactive label', colors.textSecondary, bar);
      });
    });
  }
}
