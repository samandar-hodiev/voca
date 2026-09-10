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

/// Relative luminance per WCAG 2.1.
double _luminance(Color c) {
  double channel(double v) {
    return v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
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
}
