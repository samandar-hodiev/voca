// Deleting the account: reached only from Settings, confirmed with a code the server
// checks, and destroyed only after the last question is answered in as many words.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca/core/error/failure.dart';
import 'package:voca/core/widgets/code_input.dart';
import 'package:voca/features/auth/domain/entities/auth_session.dart';
import 'package:voca/features/auth/domain/repositories/auth_repository.dart';
import 'package:voca/features/auth/domain/usecases/sign_in_with_google.dart';

import '../../helpers/app_harness.dart';

Future<void> frames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Answers the deletion calls the way the server does: a code only for the account's own
/// address, and only the right code deletes anything.
///
/// Everything this test does not exercise goes through noSuchMethod, so the fake stays the
/// size of the flow under test rather than the whole repository.
class FakeDeleteAuth implements AuthRepository {
  final requested = <String>[];
  final confirmed = <String>[];
  var deleted = false;
  var signedOut = false;

  @override
  Future<AuthSession?> restoreSession() async => const AuthSession(
    user: AuthUser(
      id: 'test-user',
      email: 'test@voca.dev',
      emailVerified: true,
      provider: 'email',
      isGuest: false,
    ),
    accessToken: 'test-access',
    refreshToken: 'test-refresh',
  );

  @override
  Future<Result<void>> requestAccountDeletionCode(String email) async {
    requested.add(email);
    return email == 'test@voca.dev'
        ? const Ok<void>(null)
        : const Err<void>(
            ApiFailure(code: 'EMAIL_MISMATCH', message: 'mismatch'),
          );
  }

  @override
  Future<Result<void>> confirmAccountDeletion(String code) async {
    confirmed.add(code);
    if (code != '123456') {
      return const Err<void>(
        ApiFailure(code: 'INVALID_VERIFICATION_CODE', message: 'wrong'),
      );
    }
    deleted = true;
    return const Ok<void>(null);
  }

  @override
  Future<void> signOut() async => signedOut = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '${invocation.memberName} is not part of this flow',
  );
}

class FakeGoogle implements GoogleIdentityTokenProvider {
  @override
  Future<void> signOut() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '${invocation.memberName} is not part of this flow',
  );
}

Finder nav(int i) => find.byKey(ValueKey('liquid-nav-$i'));

Finder get codeField => find.descendant(
  of: find.byType(CodeInput),
  matching: find.byType(TextField),
);

/// Profile -> Settings -> Delete account, then past the address step.
///
/// The journey is the point: deleting an account is reachable from exactly one place, and
/// only after Settings has been opened from Profile.
Future<void> openDeleteAccount(WidgetTester tester, FakeDeleteAuth auth) async {
  final (app, _) = buildApp(
    onboardingCompleted: true,
    signedIn: true,
    authRepository: auth,
    googleTokens: FakeGoogle(),
  );
  await tester.pumpWidget(app);
  await frames(tester, 30);

  await tester.tap(nav(3));
  await frames(tester, 10);

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
  // "Visible" can still mean under the floating tab bar.
  await tester.drag(profileList, const Offset(0, -600));
  await frames(tester, 4);
  await tester.tap(find.text('Sozlamalar'));
  await frames(tester, 10);

  final settingsList = find
      .descendant(
        of: find.byKey(const ValueKey('settings-page')),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(
    find.text('Hisobni o‘chirish'),
    200,
    scrollable: settingsList,
  );
  await tester.tap(find.text('Hisobni o‘chirish'));
  await frames(tester, 10);

  // The address is shown, not typed, so the first step is one button.
  await tester.tap(find.text('Kod yuborish'));
  await frames(tester, 6);
}

void main() {
  testWidgets('Profile no longer offers account management', (tester) async {
    final auth = FakeDeleteAuth();
    final (app, _) = buildApp(
      onboardingCompleted: true,
      signedIn: true,
      authRepository: auth,
      googleTokens: FakeGoogle(),
    );
    await tester.pumpWidget(app);
    await frames(tester, 30);
    await tester.tap(nav(3));
    await frames(tester, 10);

    expect(find.text('Hisobdan chiqish'), findsNothing);
    expect(find.text('Hisobni o‘chirish'), findsNothing);
  });

  testWidgets('the code alone deletes nothing until the last question', (
    tester,
  ) async {
    final auth = FakeDeleteAuth();
    await openDeleteAccount(tester, auth);

    expect(auth.requested, ['test@voca.dev']);
    expect(find.textContaining('6 xonali kod yuborildi'), findsOneWidget);

    await tester.enterText(codeField, '123456');
    await frames(tester, 4);
    await tester.tap(find.text('Tasdiqlash'));
    await frames(tester, 6);

    // The warning is asked again, in as many words.
    expect(find.text('Hisob o‘chirilsinmi?'), findsOneWidget);

    await tester.tap(find.text('Yo‘q'));
    await frames(tester, 6);

    expect(auth.confirmed, isEmpty, reason: 'No must not reach the server');
    expect(auth.deleted, isFalse);
  });

  testWidgets('confirming deletes the account and returns to the way in', (
    tester,
  ) async {
    final auth = FakeDeleteAuth();
    await openDeleteAccount(tester, auth);

    await tester.enterText(codeField, '123456');
    await frames(tester, 4);
    await tester.tap(find.text('Tasdiqlash'));
    await frames(tester, 6);
    await tester.tap(find.text('Ha, o‘chirilsin'));
    await frames(tester, 12);

    expect(auth.confirmed, ['123456']);
    expect(auth.deleted, isTrue);
    // The local and Google sessions end too, through the existing sign-out.
    expect(auth.signedOut, isTrue);
    expect(find.text('Mehmon sifatida kirish'), findsOneWidget);
  });

  testWidgets('a wrong code is refused and the account survives', (
    tester,
  ) async {
    final auth = FakeDeleteAuth();
    await openDeleteAccount(tester, auth);

    await tester.enterText(codeField, '000000');
    await frames(tester, 4);
    await tester.tap(find.text('Tasdiqlash'));
    await frames(tester, 6);
    await tester.tap(find.text('Ha, o‘chirilsin'));
    await frames(tester, 12);

    expect(auth.confirmed, ['000000']);
    expect(auth.deleted, isFalse);
    expect(auth.signedOut, isFalse);
  });
}
