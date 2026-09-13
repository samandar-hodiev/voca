/// The sheet a word opens into: the word, the microphone, and the score that comes back.
///
/// The whole loop happens here rather than on a pushed page. Saying a word takes about a
/// second; sending a learner to another screen and back for that would cost more attention
/// than the attempt itself. The sheet swaps its lower half between the control and the
/// result, and the word stays on screen throughout so there is never a score without the
/// thing it is a score of.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/sound_symbol.dart';
import '../../domain/entities/word.dart';
import '../../../../core/widgets/liquid_drop.dart';
import '../../../pronunciation/domain/entities/pronunciation_result.dart';
import '../../../pronunciation/presentation/controllers/recording_controller.dart';
import '../../../pronunciation/presentation/failure_text.dart';
import '../../../pronunciation/presentation/feedback_text.dart';
import '../../../pronunciation/presentation/widgets/feedback_tip.dart';
import '../../../pronunciation/presentation/widgets/phoneme_chip.dart';
import '../../../pronunciation/presentation/widgets/score_ring.dart';
import '../../../pronunciation/presentation/widgets/word_score_row.dart';
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
    builder: (_) => _WordPracticeSheet(word: word),
  );
}

class _WordPracticeSheet extends ConsumerWidget {
  const _WordPracticeSheet({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    final state = ref.watch(attemptControllerProvider);

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

              if (state.status == AttemptStatus.scored)
                _Result(result: state.result!)
              else
                _Recorder(word: word, state: state),

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

/// The control half: the microphone, what it is doing, and anything that went wrong.
class _Recorder extends ConsumerWidget {
  const _Recorder({required this.word, required this.state});

  final Word word;
  final AttemptState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    final l10n = context.l10n;

    final caption = switch (state.status) {
      AttemptStatus.recording => l10n.micRecording,
      AttemptStatus.assessing => l10n.micAssessing,
      _ => l10n.micTapToRecord,
    };

    // A failure is shown above the button, and the button stays live: the way out of
    // every one of these is to say it again.
    final problem = state.problem;
    final failure = state.failure;
    final error = problem != null
        ? recordingProblemMessage(l10n, problem)
        : failure != null
        ? assessmentFailureMessage(l10n, failure)
        : null;

    return Column(
      children: [
        if (error != null) ...[
          Semantics(
            liveRegion: true,
            child: GlassSurface(
              blur: false,
              showShadow: false,
              tint: colors.errorMuted,
              borderRadius: VocaRadius.mediumAll,
              padding: const EdgeInsets.all(VocaSpacing.sm),
              child: Text(
                error,
                style: text.bodyMedium.copyWith(color: colors.onErrorMuted),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: VocaSpacing.md),
        ],
        Semantics(
          button: true,
          enabled: state.status != AttemptStatus.assessing,
          label: caption,
          child: ExcludeSemantics(
            // Keyed because the floating bar's Practice tab wears the same microphone
            // icon, and so does the try-again button: an icon finder would be ambiguous.
            child: _MicButton(
              key: const ValueKey('mic-button'),
              status: state.status,
              onTap: state.status == AttemptStatus.assessing
                  ? null
                  : () => ref
                        .read(attemptControllerProvider.notifier)
                        .toggle(word.text),
            ),
          ),
        ),
        const SizedBox(height: VocaSpacing.sm),
        Text(
          caption,
          style: text.caption.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// The result half: the verdict, then what to do about it.
class _Result extends ConsumerWidget {
  const _Result({required this.result});

  final PronunciationResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.vocaText;
    final colors = context.vocaColors;
    final l10n = context.l10n;
    final weak = result.weakestSounds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ScoreRing(
            score: result.scores.overall,
            label: l10n.yourPronunciation,
          ),
        ),
        const SizedBox(height: VocaSpacing.md),
        Row(
          children: [
            _MiniScore(
              label: l10n.scoreAccuracy,
              value: result.scores.accuracy,
            ),
            _MiniScore(label: l10n.scoreFluency, value: result.scores.fluency),
            _MiniScore(
              label: l10n.scoreCompleteness,
              value: result.scores.completeness,
            ),
          ],
        ),

        // The sounds first: they are what the next attempt should change.
        if (weak.isNotEmpty) ...[
          const SizedBox(height: VocaSpacing.lg),
          Text(
            l10n.soundsToWorkOn,
            style: text.subtitle.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: VocaSpacing.xs),
          Wrap(
            spacing: VocaSpacing.xs,
            runSpacing: VocaSpacing.xxs,
            children: [
              for (final p in weak)
                PhonemeChip(phoneme: p.phoneme, accuracy: p.accuracy),
            ],
          ),
        ],

        // Per-word breakdown only when there is more than one word: for a single word the
        // ring above already said it, and repeating the number is noise.
        if (result.words.length > 1) ...[
          const SizedBox(height: VocaSpacing.md),
          for (final w in result.words) WordScoreRow(result: w),
        ],

        if (result.feedback.isNotEmpty) ...[
          const SizedBox(height: VocaSpacing.md),
          for (final f in result.feedback)
            if (feedbackMessage(l10n, f.messageKey, f.word ?? '') case final m?)
              FeedbackTip(message: m, tip: feedbackTip(l10n, f.tipKey)),
        ],

        const SizedBox(height: VocaSpacing.md),
        PrimaryButton(
          label: l10n.retry,
          icon: Icons.mic_rounded,
          onPressed: () => ref.read(attemptControllerProvider.notifier).reset(),
        ),
      ],
    );
  }
}

class _MiniScore extends StatelessWidget {
  const _MiniScore({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;

    return Expanded(
      child: Semantics(
        label: '$label: ${value.round()}',
        excludeSemantics: true,
        child: Column(
          children: [
            Text(
              '${value.round()}',
              style: text.subtitle.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: text.caption.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
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
class _MicButton extends StatelessWidget {
  const _MicButton({super.key, required this.status, this.onTap});

  final AttemptStatus status;
  final VoidCallback? onTap;

  /// Big enough to be the thing the sheet is about, and a comfortable target.
  static const size = 88.0;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(size / 2);
    final recording = status == AttemptStatus.recording;

    // The light mint pair in both themes. The primary button drops to deeper greens in
    // dark because a white label has to sit on it, but nothing is written on this disc,
    // and over a near-black page a deep green simply reads as a dark hole.
    const start = PremiumGreen.start;
    const end = PremiumGreen.end;

    // Thicker in dark, because thinning a colour over black darkens it instead of
    // lightening it. Fuller while recording, so the state reads across the room and not
    // only from the caption.
    final base = dark ? 0.70 : PremiumGreen.alphaLight * 0.72;
    final alpha = recording ? (base + 0.18).clamp(0.0, 1.0) : base;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox.square(
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
          // The edge lens: light gathering just inside the rim, as it does at the edge of
          // a drop of water. Brighter than the theme's, because it is read against mint
          // here rather than against a pale card.
          edgeLight: Colors.white.withValues(alpha: dark ? 0.38 : 0.55),
          rimTop: Colors.white.withValues(alpha: 0.85),
          rimBottom: end.withValues(alpha: 0.5),
          shadows: [
            BoxShadow(
              color: end.withValues(alpha: recording ? 0.34 : 0.22),
              blurRadius: recording ? 26 : 18,
              spreadRadius: -8,
              offset: const Offset(0, 6),
            ),
          ],
          child: _MicFace(status: status),
        ),
      ),
    );
  }
}

/// What sits inside the glass: the caustics, then the mark.
class _MicFace extends StatelessWidget {
  const _MicFace({required this.status});

  final AttemptStatus status;

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
        if (status == AttemptStatus.assessing)
          SizedBox.square(
            dimension: size * 0.4,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: PremiumGreen.label.withValues(alpha: 0.8),
            ),
          )
        else
          Icon(
            status == AttemptStatus.recording
                ? Icons.stop_rounded
                : Icons.mic_rounded,
            size: size * 0.4,
            color: PremiumGreen.label.withValues(alpha: 0.8),
          ),
      ],
    );
  }
}
