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

/// Uzbek text for each failure the auth flow can produce.
String authFailureMessage(Failure failure) {
  if (failure is ApiFailure) {
    return switch (failure.code) {
      'INVALID_EMAIL' => 'Elektron pochta manzili noto‘g‘ri.',
      'EMAIL_ALREADY_EXISTS' =>
        'Bu pochta bilan akkaunt allaqachon ochilgan. Kiring yoki parolni tiklang.',
      'INVALID_VERIFICATION_CODE' => 'Kod noto‘g‘ri. Qaytadan urinib ko‘ring.',
      'VERIFICATION_CODE_EXPIRED' => 'Kod muddati tugagan. Yangisini so‘rang.',
      'TOO_MANY_ATTEMPTS' => 'Juda ko‘p urinish. Yangi kod so‘rang.',
      'TOO_MANY_REQUESTS' => 'Juda ko‘p so‘rov. Biroz kuting.',
      'INVALID_PASSWORD' => 'Parol kamida 8 ta belgidan iborat bo‘lishi kerak.',
      'ACCOUNT_NOT_VERIFIED' => 'Avval pochtangizni tasdiqlang.',
      'VALIDATION_ERROR' => 'Kiritilgan ma’lumotlarda xatolik bor.',
      _ => 'Nimadir xato ketdi. Qaytadan urinib ko‘ring.',
    };
  }
  return switch (failure) {
    // Backing out is not a failure. Somebody who closed the Google picker knows what they
    // did, and "sign-in failed" would be both wrong and irritating.
    CancelledFailure() => '',
    UnauthenticatedFailure() => 'Sessiya tugagan. Qaytadan kiring.',
    NetworkFailure() => 'Internet aloqasi yo‘q.',
    // Sending is the only provider the auth flow talks to, so this is always about an
    // email that could not be delivered. Saying so is more useful than naming a service
    // the person has never heard of.
    ProviderFailure() =>
      'Bu manzilga xat yubora olmadik. Boshqa pochta kiriting yoki keyinroq urinib ko‘ring.',
    _ => 'Nimadir xato ketdi. Qaytadan urinib ko‘ring.',
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
                  authFailureMessage(failure!),
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
