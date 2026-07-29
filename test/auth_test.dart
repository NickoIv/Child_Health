import 'dart:async';

import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/data/auth_repository.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Auth repository whose signed-in state the test drives directly.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthUser? initial}) : _user = initial {
    _controller.add(_user);
  }

  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;

  AuthException? failWith;
  int signInCalls = 0;
  int registerCalls = 0;
  String? resetSentTo;
  String? changedPasswordTo;
  bool deleted = false;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> authStateChanges() =>
      Stream<AuthUser?>.multi((listener) {
        listener.add(_user);
        final sub = _controller.stream.listen(listener.add);
        listener.onCancel = sub.cancel;
      });

  void emit(AuthUser? user) {
    _user = user;
    _controller.add(user);
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    if (failWith != null) throw failWith!;
    emit(AuthUser(uid: 'uid-1', email: email));
  }

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {
    registerCalls++;
    if (failWith != null) throw failWith!;
    emit(AuthUser(uid: 'uid-1', email: email));
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    if (failWith != null) throw failWith!;
    resetSentTo = email;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (failWith != null) throw failWith!;
    changedPasswordTo = newPassword;
  }

  @override
  Future<void> deleteAccount({required String currentPassword}) async {
    if (failWith != null) throw failWith!;
    deleted = true;
    emit(null);
  }

  @override
  Future<void> signOut() async => emit(null);

  void dispose() => _controller.close();
}

void main() {
  setUpAll(() => initializeDateFormatting('ru_RU'));

  late FakeAuthRepository auth;

  setUp(() => auth = FakeAuthRepository());
  tearDown(() => auth.dispose());

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
        child: const ChildHealthApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a signed-out visitor is redirected to the login screen', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Войдите, чтобы продолжить'), findsOneWidget);
    expect(find.text('Обзор'), findsNothing);
  });

  testWidgets('signing in reveals the app', (tester) async {
    await pumpApp(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'parent@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Пароль'),
      'secret123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
    await tester.pumpAndSettle();

    expect(auth.signInCalls, 1);
    expect(find.widgetWithText(AppBar, 'Обзор'), findsOneWidget);
  });

  testWidgets('a rejected sign-in shows the message and stays put', (
    tester,
  ) async {
    auth.failWith = const AuthException('Неверный email или пароль');
    await pumpApp(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'parent@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Пароль'),
      'wrong',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
    await tester.pumpAndSettle();

    expect(find.text('Неверный email или пароль'), findsOneWidget);
    expect(find.text('Войдите, чтобы продолжить'), findsOneWidget);
  });

  testWidgets('an empty form does not reach the repository', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
    await tester.pumpAndSettle();

    expect(auth.signInCalls, 0);
    expect(find.text('Введите email'), findsOneWidget);
    expect(find.text('Введите пароль'), findsOneWidget);
  });

  testWidgets('registration mode validates the password length', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(
      find.text('Нет учётной записи — зарегистрироваться'),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'parent@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Пароль'),
      '123',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, 'Зарегистрироваться'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Минимум 6 символов'), findsOneWidget);
    expect(auth.registerCalls, 0);
  });

  testWidgets('signing out returns to the login screen', (tester) async {
    auth.emit(const AuthUser(uid: 'uid-1', email: 'parent@example.com'));
    await pumpApp(tester);
    expect(find.widgetWithText(AppBar, 'Обзор'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.account_circle_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выйти'));
    await tester.pumpAndSettle();

    expect(find.text('Войдите, чтобы продолжить'), findsOneWidget);
  });
}
