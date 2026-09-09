// core/error: the typed Failure hierarchy the UI switches on.
//
// NetworkFailure, UnauthenticatedFailure, PremiumRequiredFailure, UsageLimitReachedFailure,
// AudioValidationFailure, ProviderUnavailableFailure, UnknownFailure.
//
// Use cases return a Result over these rather than throwing, so every failure state is
// handled explicitly at the call site.
