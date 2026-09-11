// Builds the whole app for a test, with local storage faked.
//
// [onboardingCompleted] controls the branch the splash takes, which is the only piece of
// persisted state that changes routing today.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voca/app.dart';
import 'package:voca/core/config/app_config.dart';
import 'package:voca/core/config/flavor.dart';
import 'package:voca/core/di/providers.dart';
import 'package:voca/core/storage/key_value_store.dart';
import 'package:voca/core/storage/secure_storage.dart';
import 'package:voca/features/auth/domain/repositories/auth_repository.dart';
import 'package:voca/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:voca/features/home/data/repositories/home_repository_impl.dart';
import 'package:voca/features/home/presentation/controllers/home_controller.dart';
import 'package:voca/features/practice/data/repositories/practice_repository_impl.dart';
import 'package:voca/features/practice/presentation/controllers/practice_controller.dart';
import 'package:voca/features/profile/domain/entities/profile.dart';
import 'package:voca/features/profile/domain/repositories/profile_repository.dart';
import 'package:voca/features/profile/presentation/controllers/profile_controller.dart';
import 'package:voca/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:voca/features/progress/presentation/controllers/progress_controller.dart';

/// Returns the widget to pump and the container, so a test can read providers directly.
///
/// The container outlives every route, unlike a BuildContext taken from a screen the
/// navigation under test is about to dispose.
(Widget, ProviderContainer) buildApp({
  Flavor flavor = Flavor.dev,
  bool onboardingCompleted = false,
  bool signedIn = false,
  KeyValueStore? store,
  ProfileRepository profileRepository = const FakeProfileRepository(),
  AuthRepository? authRepository,
  GoogleIdentityTokenProvider? googleTokens,
}) {
  // A stored session is what the startup state machine checks, so seeding the tokens is
  // how a test says "this person is already signed in".
  final secure = InMemorySecureStore();
  if (signedIn) {
    secure.write('auth.access_token.v1', 'test-access');
    secure.write('auth.refresh_token.v1', 'test-refresh');
    secure.write('auth.user_id.v1', 'test-user');
  }

  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.forFlavor(flavor)),
      platformProvider.overrideWithValue('test'),
      keyValueStoreProvider.overrideWithValue(
        store ??
            InMemoryKeyValueStore({
              if (onboardingCompleted) 'onboarding.completed.v1': true,
              // The existing tests read Uzbek text, so they choose Uzbek rather than
              // depend on the English default. localization_test covers the default.
              'appearance.locale.v1': 'uz',
            }),
      ),
      secureStoreProvider.overrideWithValue(secure),

      // The signed-in screens read these. A test must not reach a server, and the mocks'
      // simulated latency would leave timers pending when a test ends.
      profileRepositoryProvider.overrideWithValue(profileRepository),
      if (authRepository != null)
        authRepositoryProvider.overrideWithValue(authRepository),
      if (googleTokens != null)
        googleIdentityTokenProvider.overrideWithValue(googleTokens),
      homeRepositoryProvider.overrideWithValue(
        const MockHomeRepository(latency: Duration.zero),
      ),
      practiceRepositoryProvider.overrideWithValue(
        const MockPracticeRepository(latency: Duration.zero),
      ),
      progressRepositoryProvider.overrideWithValue(
        MockProgressRepository(latency: Duration.zero),
      ),
    ],
  );

  return (
    UncontrolledProviderScope(container: container, child: const VocaApp()),
    container,
  );
}

/// A signed-in learner with a complete profile, answered without a network.
class FakeProfileRepository implements ProfileRepository {
  const FakeProfileRepository();

  @override
  Future<Result<Profile>> me() async => const Ok(
    Profile(
      id: 'test-user',
      provider: 'email',
      isGuest: false,
      email: 'test@voca.dev',
      firstName: 'Test',
      lastName: 'Learner',
      cefrLevel: 'B1',
      learningGoal: 'pronunciation',
      dailyGoalWords: 10,
    ),
  );
}
