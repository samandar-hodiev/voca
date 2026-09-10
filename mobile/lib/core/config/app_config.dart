/// Build-time configuration, supplied with `--dart-define`.
///
/// PUBLIC VALUES ONLY. Anything compiled into the app ships to every device and can be
/// read out of the binary, so no server secret may appear here: no Azure key, no AI
/// provider key, no RevenueCat secret key, no database URL. The backend holds those
/// (ARCHITECTURE.md 4.5, 18.2, 45.2).
library;

import 'flavor.dart';

class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.apiBaseUrl,
  });

  final Flavor flavor;

  /// Base URL of the Voca backend. The app talks to nothing else; it never reaches a
  /// database or a third-party API directly (ARCHITECTURE.md 31.4).
  final String apiBaseUrl;

  /// Reads configuration for [flavor], falling back to sensible local defaults so a
  /// developer can run the app with no flags at all.
  factory AppConfig.forFlavor(Flavor flavor) {
    const fromEnv = String.fromEnvironment('API_BASE_URL');

    return AppConfig(
      flavor: flavor,
      apiBaseUrl: fromEnv.isNotEmpty ? fromEnv : _defaultBaseUrl(flavor),
    );
  }

  static String _defaultBaseUrl(Flavor flavor) => switch (flavor) {
        // The backend listens on 8082 by default. 10.0.2.2 is how the Android emulator
        // reaches the host machine; iOS simulators can use localhost directly, so this
        // default is overridden with --dart-define when running on iOS.
        Flavor.dev => 'http://localhost:8082',
        Flavor.staging => 'https://staging-api.voca.example',
        Flavor.prod => 'https://api.voca.example',
      };

  bool get isProd => flavor == Flavor.prod;
}
