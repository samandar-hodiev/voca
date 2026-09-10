/// Build flavors.
///
/// dev, staging and prod use distinct bundle identifiers so all three can be installed on
/// one device at the same time (ARCHITECTURE.md 25.1).
library;

enum Flavor { dev, staging, prod }

extension FlavorX on Flavor {
  String get label => switch (this) {
        Flavor.dev => 'dev',
        Flavor.staging => 'staging',
        Flavor.prod => 'prod',
      };

  /// Whether this build should surface diagnostics such as the request ID on error
  /// screens and verbose network logging.
  bool get isDebugFriendly => this != Flavor.prod;
}
