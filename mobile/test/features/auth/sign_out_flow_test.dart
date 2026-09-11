// Signing out: always asked first, and for an account with an address, confirmed with a
// code the server checks. Nothing is cleared until the server has accepted the code.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca/core/error/failure.dart';
import 'package:voca/core/widgets/code_input.dart';
import 'package:voca/features/auth/domain/entities/auth_session.dart';
import 'package:voca/features/auth/domain/repositories/auth_repository.dart';
import 'package:voca/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:voca/features/profile/domain/entities/profile.dart';
import 'package:voca/features/profile/domain/repositories/profile_repository.dart';

import '../../helpers/app_harness.dart';

Future<void> frames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Answers the sign-out calls the way the server does: a code only for the account's
/// own address, and only the right code ends the session.
class FakeSignOutAuth implements AuthRepository {
  final requested = <String>[];
  final confirmed = <String>[];
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
  Future<Result<void>> requestSignOutCode(String email) async {
    requested.add(email);
    return email == 'test@voca.dev'
        ? const Ok<void>(null)
        : const Err<void>(
            ApiFailure(code: 'EMAIL_MISMATCH', message: 'mismatch'),
          );
  }

  @override
  Future<Result<void>> confirmSignOutCode(String code) async {
    confirmed.add(code);
    return code == '123456'
        ? const Ok<void>(null)
        : const Err<void>(
            ApiFailure(code: 'INVALID_VERIFICATION_CODE', message: 'wrong'),
          );
  }

  @override
  Future<void> signOut() async => signedOut = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGoogle implements GoogleIdentityTokenProvider {
  @override
  Future<String?> obtainIdToken() async => null;

  @override
  Future<void> signOut() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class GuestProfile implements ProfileRepository {
  const GuestProfile();

  @override
  Future<Result<Profile>> me() async => const Ok(
    Profile(id: 'guest', provider: 'guest', isGuest: true, email: null),
  );
}

Future<void> openProfile(
  WidgetTester tester,
  FakeSignOutAuth auth, {
  ProfileRepository profile = const FakeProfileRepository(),
}) async {
  final (app, _) = buildApp(
    onboardingCompleted: true,
    signedIn: true,
    authRepository: auth,
    googleTokens: FakeGoogle(),
    profileRepository: profile,
  );
  await tester.pumpWidget(app);
  await frames(tester, 30);
  await tester.tap(find.byKey(const ValueKey('liquid-nav-3')));
  await frames(tester, 10);

  final list = find
      .descendant(
        of: find.byKey(const ValueKey('profile-page')),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(
    find.text('Hisobdan chiqish'),
    200,
    scrollable: list,
  );
  // "Visible" can still mean under the floating tab bar. The list ends with room for the
  // bar, so scrolling to its end brings the button clear of it.
  await tester.drag(list, const Offset(0, -600));
  await frames(tester, 4);
  await tester.tap(find.text('Hisobdan chiqish'));
  await frames(tester, 6);
}

Finder get codeField => find.descendant(
  of: find.byType(CodeInput),
  matching: find.byType(TextField),
);

void main() {
  testWidgets('an account signs out only after the emailed code', (
    tester,
  ) async {
    final auth = FakeSignOutAuth();
    await openProfile(tester, auth);

    expect(find.text('Rostdan ham hisobdan chiqmoqchimisiz?'), findsOneWidget);
    await tester.tap(find.text('Ha, chiqish'));
    await frames(tester, 6);

    // Another address: refused, nothing sent, still signed in.
    await tester.enterText(
      find.byKey(const ValueKey('sign-out-email')),
      'someone@else.com',
    );
    await tester.tap(find.text('Kod yuborish'));
    await frames(tester, 4);
    expect(find.textContaining('tegishli emas'), findsOneWidget);
    expect(auth.signedOut, isFalse);

    // The account's own address: a code is sent.
    await tester.enterText(
      find.byKey(const ValueKey('sign-out-email')),
      'test@voca.dev',
    );
    await tester.tap(find.text('Kod yuborish'));
    await frames(tester, 4);
    expect(find.textContaining('6 xonali kod yuborildi'), findsOneWidget);

    // A wrong code: refused, still signed in.
    await tester.enterText(codeField, '000000');
    await frames(tester, 4);
    expect(find.textContaining('Kod noto‘g‘ri'), findsOneWidget);
    expect(auth.signedOut, isFalse);

    // The right code: signed out and back at the way in.
    await tester.enterText(codeField, '123456');
    await frames(tester, 10);
    expect(auth.confirmed, ['000000', '123456']);
    expect(auth.signedOut, isTrue);
    expect(find.text('Mehmon sifatida kirish'), findsOneWidget);
  });

  testWidgets('cancelling leaves the person signed in', (tester) async {
    final auth = FakeSignOutAuth();
    await openProfile(tester, auth);

    await tester.tap(find.text('Bekor qilish'));
    await frames(tester, 6);

    expect(auth.signedOut, isFalse);
    expect(auth.requested, isEmpty);
    expect(find.byKey(const ValueKey('profile-page')), findsOneWidget);
  });

  testWidgets('a guest is warned, then signed out without a code', (
    tester,
  ) async {
    final auth = FakeSignOutAuth();
    await openProfile(tester, auth, profile: const GuestProfile());

    expect(find.textContaining('Mehmon hisobida pochta yo‘q'), findsOneWidget);
    await tester.tap(find.text('Ha, chiqish'));
    await frames(tester, 10);

    expect(auth.signedOut, isTrue);
    expect(auth.requested, isEmpty);
    expect(find.text('Kod yuborish'), findsNothing);
  });
}
