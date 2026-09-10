/// Loading states.
///
/// Two shapes, chosen by how long the wait is and whether the layout is known:
///
/// * [LoadingView] for a whole screen, with an optional message.
/// * [SkeletonBox] when the shape of the content is already known, which feels faster
///   than a spinner because the page does not visibly rearrange when data lands.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A centred progress indicator for a screen that has nothing to show yet.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    return Semantics(
      liveRegion: true,
      label: message ?? 'Loading',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: colors.primary),
            ),
            if (message != null) ...[
              const SizedBox(height: VocaSpacing.md),
              Text(
                message!,
                style: context.vocaText.bodyMedium.copyWith(color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A placeholder block that pulses gently while content loads.
///
/// The pulse stops entirely when the platform asks for reduced motion; a static block is
/// still a perfectly good placeholder.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius,
  });

  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.border,
        borderRadius: widget.borderRadius ?? VocaRadius.smallAll,
      ),
      child: SizedBox(height: widget.height, width: widget.width),
    );

    if (reduceMotion) return ExcludeSemantics(child: box);

    return ExcludeSemantics(
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.45, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: VocaMotion.standardCurve),
        ),
        child: box,
      ),
    );
  }
}
