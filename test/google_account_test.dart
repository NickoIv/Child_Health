import 'dart:async';

import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/data/auth_repository.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Signed in as whichever kind of account the test asks for.
class ProviderAuthRepository implements AuthRepository {
  ProviderAuthRepository(this._user);

  final AuthUser _user;

  int changePasswordCalls = 0;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> authStateChanges() => Stream.value(_user);

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    changePasswordCalls++;
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInWith(SocialProvider provider) async {}

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> deleteAccount({required String currentPassword}) async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  setUpAll(() => initializeDateFormatting());

  Future<void> openSettings(WidgetTester tester, AuthUser user) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(ProviderAuthRepository(user)),
        ],
        child: const ChildHealthApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.account_circle_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Профиль и настройки'));
    await tester.pumpAndSettle();
  }

  const googleUser = AuthUser(
    uid: 'uid-google',
    email: 'parent@gmail.com',
    providers: {googleProvider},
  );

  const emailUser = AuthUser(uid: 'uid-email', email: 'parent@example.com');

  testWidgets('a Google account is told where its password lives', (
    tester,
  ) async {
    await openSettings(tester, googleUser);

    await tester.tap(find.text('Сменить пароль'));
    await tester.pumpAndSettle();

    // No dialog: the form could only ever have been refused.
    expect(find.text('Текущий пароль'), findsNothing);
    expect(
      find.textContaining('вход выполняется через Google'),
      findsOneWidget,
    );
  });

  testWidgets('an email account still gets the password form', (tester) async {
    await openSettings(tester, emailUser);

    await tester.tap(find.text('Сменить пароль'));
    await tester.pumpAndSettle();

    expect(find.text('Текущий пароль'), findsOneWidget);
  });

  /// The account section is the last thing on a page that keeps growing, so
  /// it has to be scrolled to rather than assumed on screen.
  Future<void> openDeleteDialog(WidgetTester tester) async {
    // ensureVisible rather than scrollUntilVisible: the list builds its lower
    // cards before they are on screen, so the finder is satisfied while the
    // button is still below the fold and the tap lands on nothing.
    await tester.ensureVisible(find.text('Удалить учётную запись'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить учётную запись'));
    await tester.pumpAndSettle();
  }

  testWidgets('deleting a Google account asks for no password', (tester) async {
    await openSettings(tester, googleUser);
    await openDeleteDialog(tester);
    await tester.pumpAndSettle();

    expect(find.text('Ваш пароль'), findsNothing);
    expect(find.textContaining('Google попросит вас войти ещё раз'), findsOneWidget);

    // The word alone is enough to arm the button.
    await tester.enterText(find.byType(TextField).last, 'УДАЛИТЬ');
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Удалить навсегда'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('deleting an email account still asks for the password', (
    tester,
  ) async {
    await openSettings(tester, emailUser);
    await openDeleteDialog(tester);

    expect(find.text('Ваш пароль'), findsOneWidget);
  });

  group('AuthUser', () {
    test('defaults to a password account', () {
      expect(emailUser.hasPassword, isTrue);
      expect(emailUser.signedInWithGoogle, isFalse);
    });

    test('knows a Google account has no password', () {
      expect(googleUser.hasPassword, isFalse);
      expect(googleUser.signedInWithGoogle, isTrue);
    });
  });
}
