/// End-to-end checks for the four ways into the product.
///
/// These drive the real app against the real backend on a simulator, so they prove that a
/// button leads to a session rather than that a mock was called. They are deliberately
/// NOT part of `flutter test`: that suite must stay hermetic and fast. Run these with
///
///     scripts/e2e-mobile.sh
///
/// which starts the backend, seeds the account the login test needs, and reads the
/// signup code out of the development mail outbox.
///
/// The signup code is fetched from a small host-side helper while the test runs. The app
/// asks the backend for a fresh code the moment the address is submitted, so a code read
/// before the run is already stale by the time the code screen appears, and a sandboxed
/// simulator app cannot read the outbox file on the host. The helper is started by the
/// runner script, listens on localhost, and is never part of the product.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voca/bootstrap.dart';
import 'package:voca/core/config/flavor.dart';
import 'package:voca/core/storage/secure_storage.dart';

/// Values supplied by the runner script.
const seededEmail = String.fromEnvironment('E2E_LOGIN_EMAIL');
const seededPassword = String.fromEnvironment('E2E_LOGIN_PASSWORD');
const signupEmail = String.fromEnvironment('E2E_SIGNUP_EMAIL');
const codeServer = String.fromEnvironment('E2E_CODE_SERVER');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Asks the host helper for the newest signup code sent to [email].
  ///
  /// Retries briefly: the backend writes the message just after it answers the request
  /// that triggered it, so the first read can arrive a moment early.
  Future<String> fetchSignupCode(String email) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    final uri = Uri.parse(
      '$codeServer?email=${Uri.encodeQueryComponent(email)}',
    );

    try {
      for (var attempt = 0; attempt < 15; attempt++) {
        final response = await (await client.getUrl(uri)).close();
        final body = await response
            .transform(const SystemEncoding().decoder)
            .join();
        if (response.statusCode == 200 && body.trim().isNotEmpty) {
          return body.trim();
        }
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    } finally {
      client.close(force: true);
    }
    fail('the host helper never produced a code for $email');
  }

  /// Puts the device back to "onboarding already done, nobody signed in", which is the
  /// state the auth entry screen is reached from.
  Future<void> resetToSignedOut() async {
    await FlutterSecureStore.create().clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool('onboarding.completed.v1', true);
  }

  /// Advances time by pumping frames.
  ///
  /// pumpAndSettle is unusable here: the liquid background animates forever, so there is
  /// never a frame with nothing scheduled and pumpAndSettle would wait until it times
  /// out. Pumping a fixed number of frames is the supported way to drive an app with a
  /// continuous animation.
  Future<void> settle(WidgetTester tester, {int frames = 40}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Waits until [finder] matches, pumping in between.
  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    int frames = 100,
  }) async {
    for (var i = 0; i < frames; i++) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 100));
    }
    fail('timed out waiting for $finder');
  }

  /// Launches the app and waits for the splash to hand over.
  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(await buildApp(Flavor.dev));
    // The splash holds for a minimum duration before it routes anywhere.
    await settle(tester, frames: 30);
  }

  Future<void> tapText(WidgetTester tester, String label) async {
    final finder = find.text(label);
    await waitFor(tester, finder);
    // The setup screens put their content in a ListView, so a target can sit under the
    // fold or be half covered. Scrolling it into view first is what makes the tap land on
    // the control rather than on the list behind it.
    await tester.ensureVisible(finder.first);
    await settle(tester, frames: 5);
    await tester.tap(finder.first, warnIfMissed: false);
    await settle(tester);
  }

  Future<void> typeInto(
    WidgetTester tester,
    int fieldIndex,
    String value,
  ) async {
    final fields = find.byType(TextField);
    await waitFor(tester, fields);
    await tester.enterText(fields.at(fieldIndex), value);
    await settle(tester, frames: 5);
  }

  testWidgets('guest sign-in reaches the product', (tester) async {
    await resetToSignedOut();
    await launch(tester);

    await waitFor(tester, find.text('Mehmon sifatida kirish'));

    await tapText(tester, 'Mehmon sifatida kirish');
    await waitFor(tester, find.byKey(const ValueKey('home-dashboard')));

    expect(
      find.byKey(const ValueKey('home-dashboard')),
      findsWidgets,
      reason: 'a guest session should land on the product',
    );
  });

  testWidgets('signing in to an existing account reaches the product', (
    tester,
  ) async {
    expect(seededEmail, isNotEmpty, reason: 'runner must pass E2E_LOGIN_EMAIL');
    await resetToSignedOut();
    await launch(tester);

    // The link reads "Akkauntingiz bormi? Kirish" and is built as one rich text span, so
    // find.text cannot see the word on its own. It is the only TextButton on the screen.
    final loginLink = find.byType(TextButton);
    await waitFor(tester, loginLink);
    await tester.ensureVisible(loginLink.first);
    await settle(tester, frames: 5);
    await tester.tap(loginLink.first, warnIfMissed: false);
    await settle(tester);

    await waitFor(tester, find.text('Xush kelibsiz'));
    await typeInto(tester, 0, seededEmail); // Elektron pochta
    await typeInto(tester, 1, seededPassword); // Parol
    await tapText(tester, 'Kirish');
    await waitFor(tester, find.byKey(const ValueKey('home-dashboard')));

    expect(
      find.byKey(const ValueKey('home-dashboard')),
      findsWidgets,
      reason: 'valid credentials should land on the product',
    );
  });

  testWidgets('creating an account with email reaches the profile form', (
    tester,
  ) async {
    expect(codeServer, isNotEmpty, reason: 'runner must pass E2E_CODE_SERVER');
    await resetToSignedOut();
    await launch(tester);

    await tapText(tester, 'Email bilan kirish');
    await waitFor(tester, find.text('Pochtangizni kiriting'));
    await typeInto(tester, 0, signupEmail);
    await tapText(tester, 'Davom etish');

    // The code screen looks like six boxes but is one hidden field behind them, so the
    // whole code goes in at once.
    await waitFor(tester, find.text('Pochtangizni tasdiqlang'));
    // Submitting the address made the backend issue a fresh code; read that one.
    final code = await fetchSignupCode(signupEmail);
    await typeInto(tester, 0, code);

    // No tap on "Tasdiqlash": the screen verifies as soon as the sixth digit lands, so
    // the button is already gone by the time a tap could reach it.
    await settle(tester);
    await waitFor(tester, find.text('Profilingizni to‘ldiring'), frames: 150);
    await typeInto(tester, 0, 'Samandar'); // Ism
    await typeInto(tester, 1, 'Xodiev'); // Familiya
    await typeInto(tester, 3, 'ParolE2E123!'); // Parol
    await typeInto(tester, 4, 'ParolE2E123!'); // Parolni tasdiqlang
    await tapText(tester, 'Akkaunt yaratish');
    await waitFor(
      tester,
      find.byKey(const ValueKey('home-dashboard')),
      frames: 150,
    );

    expect(
      find.byKey(const ValueKey('home-dashboard')),
      findsWidgets,
      reason: 'a completed signup should land on the product',
    );
  });
}
