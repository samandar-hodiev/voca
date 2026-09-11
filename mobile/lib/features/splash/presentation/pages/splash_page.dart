/// The splash screen.
///
/// Voca's first impression, and the clearest statement of its visual direction: a calm
/// liquid field, one glass surface, large type, nothing else.
///
/// The restraint is deliberate. A splash is on screen for barely a second, so anything
/// competing for attention in that window reads as noise. One subject, softly introduced.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/liquid_background.dart';
import '../controllers/splash_controller.dart';
import '../../../../l10n/l10n.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // When startup work finishes, replace the splash so it cannot be reached with the
    // back gesture: it is a transition, not a destination.
    //
    // The destination comes from the controller: onboarding on a first run, the product
    // afterwards. This screen makes no decision of its own.
    ref.listen(splashControllerProvider, (_, next) {
      final destination = next.valueOrNull;
      if (destination != null && context.mounted) {
        context.go(destination);
      }
    });

    return Scaffold(
      body: LiquidBackground(
        child: SafeArea(
          child: Center(
            child: _SplashMark(
              // Reported to assistive technology as one live region: a screen reader
              // announces "Voca, loading" rather than reading decorative parts.
              semanticLabel: context.l10n.splashSemantic,
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashMark extends StatefulWidget {
  const _SplashMark({required this.semanticLabel});

  final String semanticLabel;

  @override
  State<_SplashMark> createState() => _SplashMarkState();
}

class _SplashMarkState extends State<_SplashMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: VocaMotion.emphasized,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: VocaMotion.enterCurve,
  );

  // A small rise and settle. Starting at 0.94 rather than 0.8 keeps it a settle rather
  // than a pop; the direction is calm.
  late final Animation<double> _scale = Tween<double>(
    begin: 0.94,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: VocaMotion.enterCurve));

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;

    final mark = GlassSurface(
      padding: const EdgeInsets.symmetric(
        horizontal: VocaSpacing.xxl,
        vertical: VocaSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Voca',
            style: text.display.copyWith(
              color: colors.textPrimary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: VocaSpacing.xxs),
          Text(
            context.l10n.splashTagline,
            style: text.bodyMedium.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: VocaSpacing.xl),
          // A quiet progress hint rather than a spinner: a spinner on a splash implies
          // something might fail, and nothing here can.
          SizedBox(
            width: 96,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: colors.border,
                color: colors.primary,
              ),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      label: widget.semanticLabel,
      liveRegion: true,
      child: MediaQuery.disableAnimationsOf(context)
          ? mark
          : FadeTransition(
              opacity: _fade,
              child: ScaleTransition(scale: _scale, child: mark),
            ),
    );
  }
}
