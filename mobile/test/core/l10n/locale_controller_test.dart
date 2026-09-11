// The language choice: English by default, and a stored choice survives a restart.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca/core/di/providers.dart';
import 'package:voca/core/l10n/locale_controller.dart';
import 'package:voca/core/storage/key_value_store.dart';

ProviderContainer containerWith(InMemoryKeyValueStore store) {
  final container = ProviderContainer(
    overrides: [keyValueStoreProvider.overrideWithValue(store)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('English is the default', () async {
    final container = containerWith(InMemoryKeyValueStore({}));
    expect(container.read(localeProvider), const Locale('en'));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(localeProvider), const Locale('en'));
  });

  test('a stored choice is restored', () async {
    final container = containerWith(
      InMemoryKeyValueStore({localeStorageKey: 'ru'}),
    );
    container.read(localeProvider);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(localeProvider), const Locale('ru'));
  });

  test('an unknown stored value falls back to English', () async {
    final container = containerWith(
      InMemoryKeyValueStore({localeStorageKey: 'xx'}),
    );
    container.read(localeProvider);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(localeProvider), const Locale('en'));
  });

  test('a choice is applied at once and kept', () async {
    final store = InMemoryKeyValueStore({});
    final container = containerWith(store);
    await container.read(localeProvider.notifier).select('uz');
    expect(container.read(localeProvider), const Locale('uz'));
    expect(await store.getString(localeStorageKey), 'uz');
  });
}
