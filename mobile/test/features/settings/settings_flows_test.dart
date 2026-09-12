// The three things Settings gained: appearance behind a sheet, the profile editor, and
// the photo viewer on Profile.
//
// Taps go by icon rather than by label wherever a label is translated, so the test says
// what it means regardless of which language the harness happens to start in.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca/core/theme/theme_mode_controller.dart';
import 'package:voca/features/auth/domain/repositories/auth_repository.dart';
import 'package:voca/features/profile/domain/entities/profile.dart';
import 'package:voca/features/profile/domain/repositories/profile_repository.dart';

import '../../helpers/app_harness.dart';

Future<void> frames(WidgetTester tester, int n) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder nav(int i) => find.byKey(ValueKey('liquid-nav-$i'));

/// A profile with a picture, so the viewer has something to open.
class PhotoProfile implements ProfileRepository {
  @override
  Future<Result<Profile>> me() async => const Ok(
    Profile(
      id: 'test-user',
      provider: 'email',
      isGuest: false,
      email: 'test@voca.dev',
      firstName: 'Test',
      lastName: 'Learner',
      phone: '+998901234567',
      avatarUrl: 'https://example.invalid/avatar.png',
      dailyGoalWords: 10,
    ),
  );

  @override
  Future<Result<void>> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
  }) async => const Ok(null);
}

Future<void> openProfileTab(
  WidgetTester tester, {
  ProfileRepository? profile,
}) async {
  final (app, container) = buildApp(
    onboardingCompleted: true,
    signedIn: true,
    profileRepository: profile ?? const FakeProfileRepository(),
  );
  await tester.pumpWidget(app);
  await frames(tester, 30);
  await tester.tap(nav(3));
  await frames(tester, 10);
  _container = container;
}

late dynamic _container;

Future<void> openSettings(WidgetTester tester) async {
  final profileList = find
      .descendant(
        of: find.byKey(const ValueKey('profile-page')),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(
    find.text('Sozlamalar'),
    200,
    scrollable: profileList,
  );
  await tester.drag(profileList, const Offset(0, -600));
  await frames(tester, 4);
  await tester.tap(find.text('Sozlamalar'));
  await frames(tester, 10);
}

void main() {
  testWidgets('appearance is one row, and the sheet changes the theme', (
    tester,
  ) async {
    await openProfileTab(tester);
    await openSettings(tester);

    // One row, not three cards: the other two modes are not on the page.
    expect(find.byIcon(Icons.brightness_auto_rounded), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode_rounded), findsNothing);

    await tester.tap(find.byIcon(Icons.brightness_auto_rounded));
    await frames(tester, 10);

    // The sheet offers all three.
    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.dark_mode_rounded));
    await frames(tester, 10);

    expect(_container.read(themeModeProvider), ThemeMode.dark);
    // The row now says so, and the sheet is gone.
    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
  });

  testWidgets('the profile editor opens from Settings, already filled in', (
    tester,
  ) async {
    await openProfileTab(tester);
    await openSettings(tester);

    final settingsList = find
        .descendant(
          of: find.byKey(const ValueKey('settings-page')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byIcon(Icons.person_outline_rounded),
      200,
      scrollable: settingsList,
    );
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await frames(tester, 12);

    expect(find.byKey(const ValueKey('edit-profile-page')), findsOneWidget);
    expect(find.text('Test'), findsOneWidget);
    expect(find.text('Learner'), findsOneWidget);
    // The address is shown but cannot be edited here.
    expect(find.text('test@voca.dev'), findsOneWidget);
  });

  testWidgets('the profile photo opens in a viewer', (tester) async {
    await openProfileTab(tester, profile: PhotoProfile());

    expect(find.byType(Dialog), findsNothing);
    await tester.tap(find.byType(Image).first);
    await frames(tester, 10);

    expect(find.byType(Dialog), findsOneWidget);
  });
}
