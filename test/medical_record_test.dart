import 'package:child_health_tracker/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ru_RU'));

  Future<void> openMedical(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: ChildHealthApp()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byIcon(Icons.medical_information_outlined).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> openForm(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Добавить запись'));
    await tester.pumpAndSettle();
  }

  testWidgets('the seeded record is listed with its lab results', (
    tester,
  ) async {
    await openMedical(tester);

    expect(find.text('ОРВИ, неосложнённое течение'), findsOneWidget);
    expect(find.text('Гемоглобин'), findsOneWidget);
    // Two of the three seeded results are out of range.
    expect(find.textContaining('вне нормы'), findsOneWidget);
  });

  testWidgets('a new record appears in the list after saving', (tester) async {
    await openMedical(tester);
    await openForm(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Диагноз или причина визита'),
      'Плановый осмотр',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Врач и учреждение'),
      'Педиатр',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Плановый осмотр'), findsOneWidget);
  });

  testWidgets('a lab result is saved and flagged when out of range', (
    tester,
  ) async {
    await openMedical(tester);
    await openForm(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Диагноз или причина визита'),
      'Анализ крови',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Показатель'),
      'Ферритин',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Значение'),
      '8',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'от'), '20');
    await tester.enterText(find.widgetWithText(TextFormField, 'до'), '200');

    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Ферритин'), findsOneWidget);
    // 8 is below the 20-200 interval, so the record must say so.
    expect(find.textContaining('вне нормы'), findsWidgets);
  });

  testWidgets('an empty diagnosis blocks saving', (tester) async {
    await openMedical(tester);
    await openForm(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Укажите диагноз или причину визита'), findsOneWidget);
    // The dialog is still open.
    expect(find.text('Медицинская запись'), findsOneWidget);
  });

  testWidgets('a half-filled lab row is rejected with an explanation', (
    tester,
  ) async {
    await openMedical(tester);
    await openForm(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Диагноз или причина визита'),
      'Анализ',
    );
    // Name but no value: this is a mistake worth catching, unlike a wholly
    // blank spare row, which is silently dropped.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Показатель'),
      'Гемоглобин',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Проверьте строку'), findsOneWidget);
  });

  testWidgets('a blank spare row is dropped rather than rejected', (
    tester,
  ) async {
    await openMedical(tester);
    await openForm(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Диагноз или причина визита'),
      'Осмотр без анализов',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Осмотр без анализов'), findsOneWidget);
  });

  testWidgets('the "not yet implemented" list does not lie', (tester) async {
    // This regressed once: the list kept advertising manual entry and scan
    // attachment as missing for two releases after both shipped, because it
    // was written before the work rather than after it. A stale notice is
    // worse than none — it tells a parent to stop looking for a feature that
    // is right in front of them.
    await openMedical(tester);

    expect(
      find.widgetWithText(FloatingActionButton, 'Добавить запись'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Ручной ввод'),
      findsNothing,
      reason: 'manual entry works — the FAB above opens the form',
    );
    expect(
      find.textContaining('Прикрепление сканов'),
      findsNothing,
      reason: 'scans attach from the record form',
    );
  });

  testWidgets('deleting a record asks first and then removes it', (
    tester,
  ) async {
    await openMedical(tester);
    expect(find.text('ОРВИ, неосложнённое течение'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    expect(find.text('Удалить запись?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Удалить'));
    await tester.pumpAndSettle();

    expect(find.text('ОРВИ, неосложнённое течение'), findsNothing);
  });
}
