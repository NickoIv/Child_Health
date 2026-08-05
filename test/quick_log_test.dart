import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/features/dashboard/focus_home.dart';
import 'package:child_health_tracker/features/shared/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// The four quick actions all go through one sheet, and the sheet asks one
/// question first: is this happening now, or am I writing up something that
/// already happened? Everything here is about that split staying cheap.
void main() {
  setUpAll(() => initializeDateFormatting());

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: ChildHealthApp()));
    await tester.pumpAndSettle();
  }

  Future<void> openQuick(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(InkWell, label));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  Future<void> openDiary(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.auto_stories_outlined).first);
    await tester.pumpAndSettle();
  }

  testWidgets('every quick action asks when, and nothing else, first', (
    tester,
  ) async {
    await pumpApp(tester);

    for (final label in const [
      'Покормила',
      'Подгузник',
      'Поспал',
      'Температура',
    ]) {
      await openQuick(tester, label);

      expect(
        find.text('Сейчас'),
        findsOneWidget,
        reason: '«$label» must open on the time choice',
      );
      expect(find.text('Выбрать время'), findsOneWidget);
      // Nothing else on the first step — no note field to skip past.
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(DateTimeField), findsNothing);

      Navigator.of(tester.element(find.text('Сейчас'))).pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('«Сейчас» records a feed in three taps and no typing', (
    tester,
  ) async {
    await pumpApp(tester);
    await openQuick(tester, 'Покормила');
    await tapText(tester, 'Сейчас');

    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Левая'));
    await tester.pumpAndSettle();

    expect(find.text('Записано: кормление, левая'), findsOneWidget);
  });

  testWidgets('«Выбрать время» brings the date, the clock and the note', (
    tester,
  ) async {
    await pumpApp(tester);
    await openQuick(tester, 'Подгузник');
    await tapText(tester, 'Выбрать время');

    expect(find.byType(DateTimeField), findsOneWidget);
    expect(find.textContaining('необязательно'), findsOneWidget);
  });

  testWidgets('a note written on the second step reaches the diary', (
    tester,
  ) async {
    await pumpApp(tester);
    await openQuick(tester, 'Поспал');
    await tapText(tester, 'Выбрать время');

    await tester.enterText(find.byType(TextField).last, 'Заснул в коляске');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Час'));
    await tester.pumpAndSettle();

    await openDiary(tester);
    // The timeline folds the note into the entry's one-line summary.
    expect(find.textContaining('Заснул в коляске'), findsOneWidget);
  });

  testWidgets('temperature keeps its dial and its own save button', (
    tester,
  ) async {
    await pumpApp(tester);
    await openQuick(tester, 'Температура');
    await tapText(tester, 'Сейчас');

    expect(find.text('37.0 °C'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Записать'));
    await tester.pumpAndSettle();

    expect(find.text('Записано: 37.0 °C'), findsOneWidget);
  });

  testWidgets('the dashboard offers four actions and no more', (tester) async {
    await pumpApp(tester);

    for (final label in const [
      'Покормила',
      'Поспал',
      'Подгузник',
      'Температура',
    ]) {
      expect(
        find.widgetWithText(InkWell, label),
        findsOneWidget,
        reason: '«$label» belongs on the home screen',
      );
    }

    // Four cards, and a fifth is not hiding anywhere on the screen.
    expect(find.byType(ActionCard), findsNWidgets(4));
    // A night is a variant of sleep and lives under it; the assistant is a
    // tab. Neither was lost, and neither is a fifth primary card.
    expect(find.widgetWithText(TextButton, 'Ночной сон'), findsOneWidget);

    // The experimental cards and the extra actions are gone for good.
    for (final gone in const [
      'Лекарство',
      'Тревога',
      'Как прошёл день',
      'Что изменилось?',
    ]) {
      expect(
        find.text(gone),
        findsNothing,
        reason: '«$gone» should no longer be on the home screen',
      );
    }
  });
}
