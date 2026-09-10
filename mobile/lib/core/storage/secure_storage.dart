/// Secure storage for session tokens.
///
/// Keychain on iOS, EncryptedSharedPreferences on Android. TOKENS ONLY: an access token
/// or a refresh token must never reach SharedPreferences, a plain file, or a log line
/// (ARCHITECTURE.md 4.5, 18.2).
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The contract features depend on, so a test can substitute an in-memory store.
abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> clear();
}

class FlutterSecureStore implements SecureStore {
  const FlutterSecureStore(this._storage);

  final FlutterSecureStorage _storage;

  factory FlutterSecureStore.create() => const FlutterSecureStore(
        FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        ),
      );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> clear() => _storage.deleteAll();
}

/// In-memory store for tests.
class InMemorySecureStore implements SecureStore {
  final _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<void> clear() async => _values.clear();
}
