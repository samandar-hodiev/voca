/// A round picture of the signed-in person, or their initials when there is none.
///
/// Generic on purpose: it takes a URL and initials rather than a profile, so the core
/// widgets never depend on a feature.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

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

    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.primary.withValues(alpha: 0.72)],
        ),
      ),
      child: Text(
        initials,
        style: text.label.copyWith(
          color: colors.onPrimary,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
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

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colors.border, width: 1.5),
      ),
      child: picture,
    );
  }
}
