/// Whether the person has already been through onboarding.
///
/// An interface rather than a direct call to storage, so the routing decision can be
/// tested without a real preferences store.
library;

abstract interface class OnboardingRepository {
  /// True once onboarding has been completed or skipped.
  Future<bool> hasCompleted();

  /// Records that onboarding is done. Called when the last slide is finished and when
  /// it is skipped: from the product's point of view those are the same outcome, because
  /// forcing someone through a second time would be a worse experience than letting them
  /// skip it once.
  Future<void> markCompleted();

  /// Clears the flag. Used by tests and, later, by a developer setting.
  Future<void> reset();
}
