/// Non-secret local storage.
///
/// Small flags and preferences that make the app feel like it remembers the person:
/// whether onboarding has been seen, the last selected tab, a dismissed hint.
///
/// NOT for tokens. Access and refresh tokens belong in secure storage, backed by the
/// Keychain and the Android Keystore (ARCHITECTURE.md 4.5, 18.2). Nothing written here is
/// encrypted, and on a rooted device it is readable.
///
/// The interface exists so features depend on a contract rather than on
/// shared_preferences directly. Swapping the backing store, or faking it in a test, then
/// costs one line at the composition root.
library;

import 'package:shared_preferences/shared_preferences.dart';

abstract interface class KeyValueStore {
  Future<bool?> getBool(String key);
  Future<void> setBool(String key, bool value);
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

/// The shared_preferences implementation.
class SharedPreferencesStore implements KeyValueStore {
  SharedPreferencesStore(this._prefs);

  final SharedPreferences _prefs;

  /// Opens the store. Called once during startup.
  static Future<SharedPreferencesStore> open() async {
    return SharedPreferencesStore(await SharedPreferences.getInstance());
  }

  @override
  Future<bool?> getBool(String key) async => _prefs.getBool(key);

  @override
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  @override
  Future<String?> getString(String key) async => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

/// An in-memory implementation for tests and for any code path that must work before the
/// real store has been opened.
class InMemoryKeyValueStore implements KeyValueStore {
  InMemoryKeyValueStore([Map<String, Object>? seed])
      : _values = {...?seed};

  final Map<String, Object> _values;

  @override
  Future<bool?> getBool(String key) async => _values[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async => _values[key] = value;

  @override
  Future<String?> getString(String key) async => _values[key] as String?;

  @override
  Future<void> setString(String key, String value) async => _values[key] = value;

  @override
  Future<void> remove(String key) async => _values.remove(key);
}
