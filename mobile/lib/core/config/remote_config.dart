// core/config: remote configuration from GET /api/v1/config.
//
// Carries feature flags, free-tier limits, and the MINIMUM SUPPORTED APP VERSION.
//
// Strategically important: it lets us dark-launch a feature, disable a broken one, change
// free limits, and force an upgrade WITHOUT an app release. It is the main lever we have
// against slow store review cycles (ARCHITECTURE.md 11.2, 25.3).
