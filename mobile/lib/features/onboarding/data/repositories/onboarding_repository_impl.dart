/// Stores the onboarding flag in local key-value storage.
library;

import '../../../../core/storage/key_value_store.dart';
import '../../domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._store);

  final KeyValueStore _store;

  /// Namespaced so it cannot collide with another feature's flag.
  static const _key = 'onboarding.completed.v1';

  @override
  Future<bool> hasCompleted() async => await _store.getBool(_key) ?? false;

  @override
  Future<void> markCompleted() => _store.setBool(_key, true);

  @override
  Future<void> reset() => _store.remove(_key);
}
