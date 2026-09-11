/// A speech sound in IPA, shown the same way everywhere it appears.
///
/// Home, Practice and Progress all name sounds. One widget keeps them looking like the
/// same thing, and gives screen readers a spoken name instead of a symbol they would
/// otherwise spell out character by character.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'liquid_drop.dart';
import '../theme/app_radius.dart';

class SoundSymbol extends StatelessWidget {
  const SoundSymbol({super.key, required this.symbol, this.size = 44});

  final String symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;

    return Semantics(
      label: '$symbol tovushi',
      excludeSemantics: true,
      child: GlassBead(
        size: size,
        borderRadius: VocaRadius.largeAll,
        tint: colors.primary.withValues(alpha: 0.10),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              '/$symbol/',
              style: text.subtitle.copyWith(
                color: colors.onPrimaryMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
