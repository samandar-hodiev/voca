import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca/core/di/providers.dart';
import 'package:voca/core/storage/key_value_store.dart';
import 'package:voca/core/theme/theme_mode_controller.dart';

ProviderContainer containerWith(KeyValueStore store) {
  final container = ProviderContainer(
    overrides: [keyValueStoreProvider.overrideWithValue(store)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('it follows the system until a choice is made', () {
    final container = containerWith(InMemoryKeyValueStore());
    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  test('a choice applies immediately and is written down', () async {
    final store = InMemoryKeyValueStore();
    final container = containerWith(store);

    await container.read(themeModeProvider.notifier).select(ThemeMode.dark);

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(await store.getString(themeModeStorageKey), 'dark');
  });

  test('a stored choice survives a restart', () async {
    final store = InMemoryKeyValueStore({themeModeStorageKey: 'dark'});
    final container = containerWith(store);

    // The read is asynchronous, so the first value is still the default.
    expect(container.read(themeModeProvider), ThemeMode.system);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  test('every mode round-trips through storage', () async {
    for (final mode in ThemeMode.values) {
      final store = InMemoryKeyValueStore();
      final container = containerWith(store);
      await container.read(themeModeProvider.notifier).select(mode);

      final reopened = containerWith(store);
      // The first read is what builds the notifier and starts the restore, so it has to
      // happen before the wait rather than after it.
      reopened.read(themeModeProvider);
      await Future<void>.delayed(Duration.zero);
      expect(reopened.read(themeModeProvider), mode, reason: '$mode did not survive');
    }
  });

  // A value that is not one of the three must not throw on launch. Falling back to the
  // system setting is the only safe answer.
  test('an unreadable stored value falls back to the system setting', () async {
    final store = InMemoryKeyValueStore({themeModeStorageKey: 'midnight'});
    final container = containerWith(store);
    container.read(themeModeProvider);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(themeModeProvider), ThemeMode.system);
  });
}
