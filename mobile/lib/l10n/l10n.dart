/// The app's strings, reached as `context.l10n`.
library;

import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nContext on BuildContext {
  /// The strings in the current language. Falls back to English where no localizations
  /// are installed, such as a widget pumped on its own in a test.
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      lookupAppLocalizations(const Locale('en'));
}
