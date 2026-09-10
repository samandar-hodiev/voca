/// Which theme the person chose, and where that choice is kept.
///
/// Three states, not two. "System" is a real answer, not the absence of one: somebody who
/// has their phone switch at sunset expects the app to switch with it, and forcing them
/// to pick a side takes that away.
///
/// The choice lives in local key-value storage rather than on the server. It is a device
/// preference: the same person may want dark on a phone at night and light on a tablet in
/// daylight, and it must apply on the very first frame, before any network call could
/// answer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';

/// Storage key. Versioned so a later change of representation cannot be misread as a
/// valid old value.
const themeModeStorageKey = 'appearance.theme_mode.v1';

/// Reads and writes the chosen theme.
///
/// The initial value is [ThemeMode.system] and the stored choice replaces it as soon as
/// the read completes. Waiting for storage before the first frame would mean a blank
/// screen for the sake of a preference most people never change.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _restore();
    return ThemeMode.system;
  }

  Future<void> _restore() async {
    final stored = await ref.read(keyValueStoreProvider).getString(themeModeStorageKey);
    final restored = _parse(stored);
    if (restored != null) state = restored;
  }

  /// Records a choice and applies it immediately.
  Future<void> select(ThemeMode mode) async {
    state = mode;
    await ref.read(keyValueStoreProvider).setString(themeModeStorageKey, _name(mode));
  }

  static String _name(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  /// Returns null for anything unrecognised, so a corrupted value falls back to the
  /// system setting instead of throwing on launch.
  static ThemeMode? _parse(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => null,
      };
}

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
