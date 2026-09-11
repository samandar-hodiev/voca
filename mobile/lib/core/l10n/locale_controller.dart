/// Which language the app speaks, and where that choice is kept.
///
/// English by default, with Uzbek and Russian to choose from. Like the theme, the choice
/// is a device preference kept in local storage rather than on the server, so it applies
/// on the very first frame, before any network call could answer.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';

/// Storage key. Versioned so a later change of representation cannot be misread as a
/// valid old value.
const localeStorageKey = 'appearance.locale.v1';

/// The languages the app ships, in the order they are offered.
const appLanguages = ['en', 'uz', 'ru'];

/// Reads and writes the chosen language.
///
/// Starts in English and replaces it with the stored choice as soon as the read
/// completes, rather than holding the first frame for a preference.
class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    _restore();
    return const Locale('en');
  }

  Future<void> _restore() async {
    final stored = await ref
        .read(keyValueStoreProvider)
        .getString(localeStorageKey);
    // Anything unrecognised is ignored, so a corrupted value falls back to English
    // instead of throwing on launch.
    if (stored != null && appLanguages.contains(stored)) state = Locale(stored);
  }

  /// Records a choice and applies it immediately.
  Future<void> select(String code) async {
    if (!appLanguages.contains(code)) return;
    state = Locale(code);
    await ref.read(keyValueStoreProvider).setString(localeStorageKey, code);
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);
