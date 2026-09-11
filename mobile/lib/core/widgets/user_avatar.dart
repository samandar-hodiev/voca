/// A round picture of the signed-in person, or their initials when there is none.
///
/// Generic on purpose: it takes a URL and initials rather than a profile, so the core
/// widgets never depend on a feature.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'liquid_drop.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.initials,
    this.imageUrl,
    this.size = 44,
  });

  final String initials;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;

    final fallback = SizedBox.square(
      dimension: size,
      child: LiquidDrop(
        glow: false,
        child: Center(
          child: Text(
            initials,
            style: text.label.copyWith(
              color: colors.onPrimary,
              fontSize: size * 0.36,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );

    // A picture that fails to load, or is still loading, shows the initials. A broken
    // image icon in somebody's own avatar reads as the app being broken.
    final url = imageUrl;
    final picture = url == null
        ? fallback
        : ClipOval(
            child: Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : fallback,
            ),
          );

    return GlassBead(padding: const EdgeInsets.all(3), child: picture);
  }
}
