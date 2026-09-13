// Saying a word, end to end, with a fake microphone and a fake server.
//
// This is the loop the whole feature exists for, so it is checked as a learner meets it:
// open a word, tap once to record, tap again to stop, and read a score. The mic button was
// disabled for months while the backend was built; a test that only checked the sheet
// opens would not have noticed if it stayed that way.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca/core/error/failure.dart';
import 'package:voca/features/auth/domain/repositories/auth_repository.dart';
import 'package:voca/features/pronunciation/presentation/widgets/phoneme_chip.dart';
import 'package:voca/l10n/l10n.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/pronunciation_fakes.dart';

Future<void> frames(WidgetTester tester, int n) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder nav(int i) => find.byKey(ValueKey('liquid-nav-$i'));

/// The sheet's record control. Keyed rather than found by icon: the Practice tab in the
/// floating bar carries a microphone too.
final mic = find.byKey(const ValueKey('mic-button'));

/// The harness runs in Uzbek, so expectations are looked up rather than transcribed.
final uz = lookupAppLocalizations(const Locale('uz'));

Future<void> openWord(WidgetTester tester) async {
  await tester.tap(nav(1));
  await frames(tester, 10);
  await tester.tap(find.text('think').first);
  await frames(tester, 12);
}

void main() {
  testWidgets('records a word and shows the score that comes back', (
    tester,
  ) async {
    final recorder = FakeRecorder();
    final repository = FakeRepository(() => Ok(sampleResult()));
    final (app, _) = buildApp(
      onboardingCompleted: true,
      signedIn: true,
      recorder: recorder,
      pronunciationRepository: repository,
    );
    await tester.pumpWidget(app);
    await frames(tester, 30);
    await openWord(tester);

    // Idle: the microphone is offered, and it is live.
    expect(find.text(uz.micTapToRecord), findsOneWidget);
    await tester.tap(mic);
    await frames(tester, 4);

    // Recording: the control has become a stop button.
    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
    expect(find.text(uz.micRecording), findsOneWidget);

    await tester.tap(mic);
    await frames(tester, 12);

    // Scored: the overall number, the sub-scores, the weak sound, and advice that is a
    // sentence in the reader's language rather than a key from the server.
    expect(find.text('86'), findsOneWidget);
    expect(find.text(uz.scoreAccuracy), findsOneWidget);
    // Scoped to the chip: the sheet's header and the word card behind it both show the
    // focus sound too, so a bare text finder would match three.
    expect(
      find.descendant(of: find.byType(PhonemeChip), matching: find.text('/θ/')),
      findsOneWidget,
    );
    // A sound in the seventies counts now. Under the old bar of 60 this chip was absent
    // and the learner was told nothing about it.
    expect(
      find.descendant(of: find.byType(PhonemeChip), matching: find.text('/ɪ/')),
      findsOneWidget,
    );
    expect(find.text(uz.feedbackMispronunciation('think')), findsOneWidget);
    expect(find.text(uz.tipTongueBetweenTeeth), findsOneWidget);

    // What was actually sent.
    expect(repository.submittedText, 'think');
    expect(repository.submittedDuration, 900);
  });

  testWidgets('an unreachable server is said plainly, and the mic stays live', (
    tester,
  ) async {
    final (app, _) = buildApp(
      onboardingCompleted: true,
      signedIn: true,
      recorder: FakeRecorder(),
      pronunciationRepository: FakeRepository(
        () => const Err(ServerUnreachableFailure(message: 'no route')),
      ),
    );
    await tester.pumpWidget(app);
    await frames(tester, 30);
    await openWord(tester);

    await tester.tap(mic);
    await frames(tester, 4);
    await tester.tap(mic);
    await frames(tester, 12);

    expect(find.text(uz.errorServerUnreachable), findsOneWidget);
    // Not "no internet": the phone's connection is fine, ours is the thing that is down.
    expect(find.text(uz.errorNoInternet), findsNothing);
    // And the way out is to try again, so the control is back to offering a recording.
    expect(mic, findsOneWidget);
    expect(find.text(uz.micTapToRecord), findsOneWidget);
  });

  testWidgets('a refused microphone explains itself', (tester) async {
    final (app, _) = buildApp(
      onboardingCompleted: true,
      signedIn: true,
      recorder: FakeRecorder(permitted: false),
      pronunciationRepository: FakeRepository(() => Ok(sampleResult())),
    );
    await tester.pumpWidget(app);
    await frames(tester, 30);
    await openWord(tester);

    await tester.tap(mic);
    await frames(tester, 6);

    expect(find.text(uz.micPermissionDenied), findsOneWidget);
  });

  testWidgets('saying the wrong word names what was heard', (tester) async {
    // Not "we couldn't hear you": the learner spoke perfectly clearly, they just said
    // something else. Telling them the microphone failed sends them off to fix a
    // microphone that works.
    final (app, _) = buildApp(
      onboardingCompleted: true,
      signedIn: true,
      recorder: FakeRecorder(),
      pronunciationRepository: FakeRepository(
        () => const Err(
          ApiFailure(
            code: 'WRONG_WORD_SPOKEN',
            message: 'Boshqa so‘z aytildi.',
            details: {'heard': 'World', 'expected': 'think'},
          ),
        ),
      ),
    );
    await tester.pumpWidget(app);
    await frames(tester, 30);
    await openWord(tester);

    await tester.tap(mic);
    await frames(tester, 4);
    await tester.tap(mic);
    await frames(tester, 12);

    expect(find.text(uz.errorWrongWord('World')), findsOneWidget);
    // And emphatically not the silence message.
    expect(find.text(uz.errorNoSpeech), findsNothing);
  });

  testWidgets('the daily limit is explained, not blamed on the microphone', (
    tester,
  ) async {
    // Running out of practice for the day is a normal thing to hit, and it is the one
    // failure here that no amount of trying again will clear. It has to read as a limit.
    final (app, _) = buildApp(
      onboardingCompleted: true,
      signedIn: true,
      recorder: FakeRecorder(),
      pronunciationRepository: FakeRepository(
        () => Err(
          UsageLimitFailure(
            message: 'limit reached',
            resetsAt: DateTime.now().add(const Duration(hours: 3)),
          ),
        ),
      ),
    );
    await tester.pumpWidget(app);
    await frames(tester, 30);
    await openWord(tester);

    await tester.tap(mic);
    await frames(tester, 4);
    await tester.tap(mic);
    await frames(tester, 12);

    expect(find.text(uz.errorUsageLimit), findsOneWidget);
    expect(find.text(uz.errorNoSpeech), findsNothing);
  });
}
