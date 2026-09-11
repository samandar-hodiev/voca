# Languages

The app ships in three languages: **English** (the default), **Uzbek** and **Russian**.

## Choosing a language

- A first launch is in English. The language can be changed on the very first screen,
  with the globe button at the top left, before anything else has to be read.
- Later it is changed in Settings, under Language.
- The choice is kept on the device (`appearance.locale.v1`), like the theme, so it applies
  on the first frame without waiting for the network.
- Each language is always named in itself (English, O‘zbekcha, Русский), so anyone can
  find their own.

## Where the strings live

- `mobile/lib/l10n/app_en.arb` is the template; `app_uz.arb` and `app_ru.arb` must cover
  every key. `flutter gen-l10n` (run by `flutter pub get`, configured in
  `mobile/l10n.yaml`) generates `AppLocalizations`.
- Widgets read strings as `context.l10n.someKey`. Where no localizations are installed,
  such as a widget pumped on its own in a test, it falls back to English.
- Counts use ICU plural rules: Russian has three forms (1 день, 2 дня, 5 дней), English
  two, and Uzbek does not inflect the noun after a number.
- Levels, goals and weekdays are stored as identifiers (`A1`, `ielts`, `1`–`7`); their
  names come from `select` messages, so a translation can never change what is stored.

## Adding a string

1. Add the key to `app_en.arb`, with a description and placeholders if it has any.
2. Add the same key to `app_uz.arb` and `app_ru.arb`.
3. Use it as `context.l10n.newKey`. Never put user-facing text directly in a widget.

## Not translated

- Word meanings in the practice data are Uzbek today, so they are shown with the Uzbek
  interface only; the other languages show the sounds (IPA). Russian meanings come with
  the word content from the backend.
- Server error messages are never shown as text. The app maps the stable error code to a
  string in the current language.
