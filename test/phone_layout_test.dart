import 'package:child_health_tracker/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// The app is used on a phone, one-handed, by someone holding a baby.
///
/// Every test here runs at a real handset size. Flutter throws on an overflow,
/// so simply building these screens at 390 logical pixels is a genuine check
/// that nothing spills off the side — which is the failure a desktop-sized
/// test would never see.
void main() {
  setUpAll(() => initializeDateFormatting('ru_RU'));

  /// iPhone 14 / Pixel 7 class, the common case.
  Future<void> pumpPhone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: ChildHealthApp()));
    await tester.pumpAndSettle();
  }

  testWidgets('the dashboard fits a phone screen', (tester) async {
    await pumpPhone(tester);
    expect(find.widgetWithText(AppBar, 'Обзор'), findsOneWidget);
    expect(find.text('Демо-профиль'), findsWidgets);
  });

  testWidgets('the bottom bar is used instead of the rail', (tester) async {
    await pumpPhone(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('quick actions are all reachable', (tester) async {
    await pumpPhone(tester);
    // Five targets across two rows; on one row they would each be too small
    // to hit reliably.
    for (final label in const [
      'Покормила',
      'Подгузник',
      'Температура',
      'Спросить',
      'Тревога',
    ]) {
      expect(
        find.text(label),
        findsOneWidget,
        reason: '«$label» must be on the phone dashboard',
      );
    }
  });

  testWidgets('logging a feed takes two taps and shows in the count', (
    tester,
  ) async {
    await pumpPhone(tester);

    await tester.tap(find.text('Покормила'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Левая'));
    await tester.pumpAndSettle();

    expect(find.text('кормлений'), findsOneWidget);
    expect(find.textContaining('Записано'), findsWidgets);
  });

  testWidgets('logging a nappy counts it as wet', (tester) async {
    await pumpPhone(tester);

    await tester.tap(find.text('Подгузник'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Мокрый и стул'));
    await tester.pumpAndSettle();

    // One nappy, two facts — it must appear on both tallies.
    expect(find.text('мокрых'), findsOneWidget);
    expect(find.text('стул'), findsOneWidget);
  });

  testWidgets('the assistant fits a phone', (tester) async {
    await pumpPhone(tester);
    await tester.tap(find.byIcon(Icons.lightbulb_outline).first);
    await tester.pumpAndSettle();

    expect(find.text('Проверить тревожные признаки'), findsOneWidget);
    expect(find.text('Спросить своими словами'), findsOneWidget);
  });

  testWidgets('an article reads without overflowing', (tester) async {
    await pumpPhone(tester);
    await tester.tap(find.byIcon(Icons.lightbulb_outline).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'температура');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Температура у ребёнка').first);
    await tester.pumpAndSettle();

    expect(find.text('Что делать сейчас'), findsOneWidget);
    expect(find.text('Скорая помощь — 103'), findsOneWidget);
  });

  testWidgets('the growth chart renders on a phone', (tester) async {
    await pumpPhone(tester);
    await tester.tap(find.byIcon(Icons.show_chart_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Динамика показателей'), findsOneWidget);
  });

  testWidgets('the triage checklist fits', (tester) async {
    await pumpPhone(tester);
    await tester.tap(find.text('Тревога'));
    await tester.pumpAndSettle();

    expect(find.text('Отметьте всё, что есть'), findsOneWidget);

    // The checklist is long on a phone, so the button starts off-screen and
    // the list has not built it yet. Scrolling to it is also the check that
    // a thumb can actually reach it.
    await tester.scrollUntilVisible(
      find.text('Оценить состояние'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Оценить состояние'), findsOneWidget);
  });
}
