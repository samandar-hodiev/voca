/// The sheet a word opens into: the word itself, and where recording will happen.
///
/// Recording and scoring are the pronunciation assessment feature, which is not built yet.
/// The control is shown, disabled, and says so. A button that does nothing when tapped is
/// worse than one that is honestly unavailable.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/sound_symbol.dart';
import '../../domain/entities/practice_item.dart';
import '../../domain/entities/word.dart';
import '../../../../core/widgets/liquid_drop.dart';
import '../../../../l10n/l10n.dart';

Future<void> showWordPracticeSheet(BuildContext context, Word word) {
  return showModalBottomSheet<void>(
    context: context,
    // On the root navigator, not the tab's own. The shell paints the floating bar in the
    // Scaffold's bottomNavigationBar slot, which sits above everything inside the body;
    // a sheet pushed onto the branch navigator lives in that body and comes up UNDER the
    // bar, with its close button unreachable. The root navigator is above the shell, so
    // the sheet and its barrier cover the bar the way a modal should.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _WordPracticeSheet(attempt: PracticeAttempt(word: word)),
  );
}

class _WordPracticeSheet extends StatelessWidget {
  const _WordPracticeSheet({required this.attempt});

  final PracticeAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    final word = attempt.word;

    return Padding(
      padding: const EdgeInsets.all(VocaSpacing.md),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(
          VocaSpacing.xl,
          VocaSpacing.md,
          VocaSpacing.xl,
          VocaSpacing.xl,
        ),
        // Scrolls rather than overflows: at the largest text sizes on a small phone the
        // word, its sounds, the record control and the close button are taller than the
        // sheet is allowed to be.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: VocaSpacing.lg),
              SoundSymbol(symbol: word.focusSound, size: 56),
              const SizedBox(height: VocaSpacing.md),
              Semantics(
                header: true,
                child: Text(
                  word.text,
                  style: text.display.copyWith(color: colors.textPrimary),
                  textAlign: TextAlign.center,
                ),
              ),
              Text(
                word.ipa,
                style: text.title.copyWith(color: colors.textSecondary),
              ),
              // The meanings on hand are Uzbek, so only the Uzbek interface shows one.
              // The other languages skip the line rather than leave a gap where it would be.
              if (Localizations.localeOf(context).languageCode == 'uz') ...[
                const SizedBox(height: VocaSpacing.xs),
                Text(
                  word.meaningUz,
                  style: text.body.copyWith(color: colors.textSecondary),
                ),
              ],
              const SizedBox(height: VocaSpacing.xl),
              Semantics(
                button: true,
                enabled: false,
                label: context.l10n.recordingUnavailable,
                child: const ExcludeSemantics(child: _MicButton()),
              ),
              const SizedBox(height: VocaSpacing.sm),
              Text(
                context.l10n.scoringComingNext,
                style: text.caption.copyWith(color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: VocaSpacing.lg),
              SecondaryButton(
                label: context.l10n.close,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The record control: premium green liquid glass, in a circle.
///
/// It used to be a solid brand-coloured drop under a flat 45% opacity, which is why it
/// came out as a grey disc with no light in it: opacity fades the highlight and the shade
/// along with the colour, so what is left is flat. The colour is thinned instead, and the
/// light is kept.
///
/// Built on [GlassSurface] rather than by hand, so it gets the same liquid the rest of the
/// app is made of: the backdrop blur and saturation boost, the light bending round the
/// inside of the rim, and the specular rim itself. On top of that sits the one thing a
/// flat pane does not need — a caustic, the pool of light that gathers inside a drop and
/// is what makes a circle read as domed rather than printed.
///
/// Disabled until pronunciation scoring exists, and it says so three ways that do not rely
/// on colour: the semantics mark the button disabled, the caption underneath says the
/// feature is coming, and the glass carries less colour than an enabled control.
class _MicButton extends StatelessWidget {
  const _MicButton();

  /// Big enough to be the thing the sheet is about, and to stay a comfortable target once
  /// it can actually be pressed.
  static const size = 88.0;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(size / 2);

    // The light mint pair in both themes. The primary button drops to deeper greens in
    // dark because a white label has to sit on it, but nothing is written on this disc,
    // and over a near-black page a deep green simply reads as a dark hole.
    const start = PremiumGreen.start;
    const end = PremiumGreen.end;

    // Thinner than the primary button in light, because the control cannot be used yet
    // and should read as green glass waiting rather than as a call to action. Thicker in
    // dark, because thinning a colour over black darkens it instead of lightening it.
    final alpha = dark ? 0.70 : PremiumGreen.alphaLight * 0.72;

    return SizedBox.square(
      dimension: size,
      child: GlassSurface(
        borderRadius: radius,
        padding: EdgeInsets.zero,
        borderWidth: 1.2,
        // The gradient is the fill: the theme tint would mute the green under it.
        tint: Colors.transparent,
        tintGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            start.withValues(alpha: alpha),
            end.withValues(alpha: alpha),
          ],
        ),
        highlight: Colors.white.withValues(alpha: 0.42),
        // The edge lens: light gathering just inside the rim, as it does at the edge of a
        // drop of water. Brighter than the theme's, because it is read against mint here
        // rather than against a pale card.
        edgeLight: Colors.white.withValues(alpha: dark ? 0.38 : 0.55),
        rimTop: Colors.white.withValues(alpha: 0.85),
        rimBottom: end.withValues(alpha: 0.5),
        shadows: [
          BoxShadow(
            color: end.withValues(alpha: 0.22),
            blurRadius: 18,
            spreadRadius: -8,
            offset: const Offset(0, 6),
          ),
        ],
        child: const _MicFace(),
      ),
    );
  }
}

/// What sits inside the glass: the caustics, then the mark.
class _MicFace extends StatelessWidget {
  const _MicFace();

  @override
  Widget build(BuildContext context) {
    const size = _MicButton.size;

    return Stack(
      alignment: Alignment.center,
      children: [
        // The specular pool, up and to the left, where the light comes from everywhere
        // else in the app. A drop is domed, so its brightest point is not its centre.
        Align(
          alignment: const Alignment(-0.35, -0.5),
          child: SizedBox(
            width: size * 0.46,
            height: size * 0.32,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x8CFFFFFF), Color(0x00FFFFFF)],
                ),
              ),
            ),
          ),
        ),
        // The caustic underneath: light that has passed through the drop and gathered
        // again at the far side. Faint on purpose; it is a hint of depth, not a second
        // highlight competing with the first.
        Align(
          alignment: const Alignment(0.3, 0.62),
          child: SizedBox(
            width: size * 0.55,
            height: size * 0.22,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    PremiumGreen.start.withValues(alpha: 0.55),
                    PremiumGreen.start.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Icon(
          Icons.mic_rounded,
          size: size * 0.4,
          color: PremiumGreen.label.withValues(alpha: 0.8),
        ),
      ],
    );
  }
}
