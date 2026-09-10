/// Onboarding state and its dependencies.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../data/repositories/onboarding_repository_impl.dart';
import '../../domain/entities/onboarding_slide.dart';
import '../../domain/repositories/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepositoryImpl(ref.watch(keyValueStoreProvider));
});

/// Whether onboarding has already been seen. Read by the splash to decide where to go.
final onboardingCompletedProvider = FutureProvider<bool>((ref) {
  return ref.watch(onboardingRepositoryProvider).hasCompleted();
});

/// The slides.
///
/// Three, deliberately. Onboarding earns attention it has not been given yet, so it says
/// only what the product is, how it works, and what it asks of the person. Anything more
/// gets skipped.
///
/// Text is Uzbek, the first UI language. It moves into ARB files with the localization
/// work; keeping it here now would be the only copy, and pretending otherwise by adding a
/// key indirection with a single language behind it would be ceremony.
const onboardingSlides = <OnboardingSlide>[
  OnboardingSlide(
    title: 'Aniq talaffuz qiling',
    body: 'Ingliz tilidagi so‘zlarni to‘g‘ri talaffuz qilishni mashq qiling. '
        'Har bir so‘z uchun namunani eshiting.',
  ),
  OnboardingSlide(
    title: 'Ovozingiz tahlil qilinadi',
    body: 'Talaffuzingizni yozib oling. Har bir tovush alohida baholanadi va '
        'qaysi joyda xato qilganingiz ko‘rsatiladi.',
  ),
  OnboardingSlide(
    title: 'Har kuni bir oz',
    body: 'Qiynalayotgan tovushlaringiz kuzatib boriladi. Kunlik mashq va '
        'ketma-ketlik natijani mustahkamlaydi.',
  ),
];
