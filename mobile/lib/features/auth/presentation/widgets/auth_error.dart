/// Shows an auth failure in language a person can act on.
///
/// Maps the backend's stable error CODE, never its message text, which is what lets the
/// API answer in English while the app speaks Uzbek (ARCHITECTURE.md 19.1).
library;

import 'package:flutter/material.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../l10n/l10n.dart';

/// Uzbek text for each failure the auth flow can produce.
String authFailureMessage(AppLocalizations l, Failure failure) {
  if (failure is ApiFailure) {
    return switch (failure.code) {
      'INVALID_EMAIL' => l.errorInvalidEmail,
      'EMAIL_MISMATCH' => l.errorEmailMismatch,
      'EMAIL_ALREADY_EXISTS' => l.errorEmailExists,
      'INVALID_VERIFICATION_CODE' => l.errorInvalidCode,
      'VERIFICATION_CODE_EXPIRED' => l.errorCodeExpired,
      'TOO_MANY_ATTEMPTS' => l.errorTooManyAttempts,
      'TOO_MANY_REQUESTS' => l.errorTooManyRequests,
      'INVALID_PASSWORD' => l.errorInvalidPassword,
      'ACCOUNT_NOT_VERIFIED' => l.errorNotVerified,
      'VALIDATION_ERROR' => l.errorValidation,
      _ => l.errorGeneric,
    };
  }
  return switch (failure) {
    // Backing out is not a failure. Somebody who closed the Google picker knows what they
    // did, and "sign-in failed" would be both wrong and irritating.
    CancelledFailure() => '',
    UnauthenticatedFailure() => l.errorSessionExpired,
    NetworkFailure() => l.errorNoInternet,
    // Sending is the only provider the auth flow talks to, so this is always about an
    // email that could not be delivered. Saying so is more useful than naming a service
    // the person has never heard of.
    ProviderFailure() => l.errorEmailDelivery,
    _ => l.errorGeneric,
  };
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.failure});

  final Failure? failure;

  @override
  Widget build(BuildContext context) {
    if (failure == null || failure is CancelledFailure) {
      return const SizedBox.shrink();
    }

    final colors = context.vocaColors;

    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: VocaSpacing.md),
        child: GlassSurface(
          edgeGlow: false,
          blur: false,
          showShadow: false,
          tint: colors.errorMuted,
          borderRadius: VocaRadius.mediumAll,
          padding: const EdgeInsets.all(VocaSpacing.sm),
          child: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 18,
                color: colors.onErrorMuted,
              ),
              const SizedBox(width: VocaSpacing.xs),
              Expanded(
                child: Text(
                  authFailureMessage(context.l10n, failure!),
                  style: context.vocaText.bodyMedium.copyWith(
                    color: colors.onErrorMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
