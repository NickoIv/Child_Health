import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/core/analytics/daily_care.dart';
import 'package:child_health_tracker/core/care/pumping.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The one entry in this diary that is about the mother.
///
/// What is tested is mostly what pumping is *not*: not a feed, not in the
/// day's tally, not something the app has an opinion about. The number she
/// keeps is a total, and totals are all it gives back.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeDateFormatting);

  final now = DateTime(2026, 8, 9, 14);

  DevelopmentLog pump(int ml, DateTime at) => DevelopmentLog(
    id: '$ml$at',
    childId: 'c1',
    date: at,
    type: LogType.note,
    title: LogTitles.pumping,
    milkMl: ml,
  );

  group('a session', () {
    test('is a note, and nobody was fed', () {
      final log = pump(120, now);
      expect(log.isPumping, isTrue);
      expect(log.type, LogType.note);

      // The day's tally is the child's. Counting milk into a bottle as a feed
      // would tell a mother checking herself against «8-12 кормлений» that she
      // is doing better than she is.
      final care = dailyCareFor([log], now);
      expect(care.feedings, 0);
      expect(care.isEmpty, isTrue);
    });

    test('survives the trip to storage and back', () {
      final map = pump(120, now).toMap();
      expect(map['milk_ml'], 120);

      final read = DevelopmentLog.fromMap('x', map);
      expect(read.milkMl, 120);
      expect(read.isPumping, isTrue);
    });

    test('is not mistaken for a measurement of the child', () {
      // Millilitres of milk are not a metric of a body, so they are nowhere
      // near the map the growth chart reads.
      final log = pump(120, now);
      expect(log.metrics.isEmpty, isTrue);
      expect(log.type, isNot(LogType.measurement));
    });
  });

  group('the day', () {
    test('adds up, and stops at midnight', () {
      final logs = [
        pump(120, now),
        pump(80, now.subtract(const Duration(hours: 5))),
        pump(200, now.subtract(const Duration(days: 1))),
      ];

      expect(pumpedOnDay(logs, now), 200);
      expect(pumpedOnDay(logs, now.subtract(const Duration(days: 1))), 200);
      expect(pumpedOnDay(logs, now.add(const Duration(days: 1))), 0);
    });

    test('counts nothing when nothing was expressed', () {
      expect(pumpedOnDay(const [], now), 0);
      expect(
        pumpingIn([
          DevelopmentLog(
            id: 'n',
            childId: 'c1',
            date: now,
            type: LogType.note,
            title: 'Заметка',
            description: 'Улыбался',
          ),
        ]),
        isEmpty,
      );
    });
  });

  group('on the screen', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<void> pumpApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const ProviderScope(child: ChildHealthApp()));
      await tester.pumpAndSettle();
    }

    testWidgets('is reached from the feed, quietly', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.widgetWithText(InkWell, 'Покормила'));
      await tester.pumpAndSettle();

      // Under the three buttons rather than beside them: a mother who does
      // not pump should not read past it forty times a day.
      expect(find.text('Я сцеживалась'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Я сцеживалась'), findsOneWidget);
    });

    testWidgets('opens on a hundred and steps in tens', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.widgetWithText(InkWell, 'Покормила'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Я сцеживалась'));
      await tester.pumpAndSettle();

      expect(find.text('100 мл'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('110 мл'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.remove));
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      expect(find.text('90 мл'), findsOneWidget);
    });

    testWidgets('writes it down and says so', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.widgetWithText(InkWell, 'Покормила'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Я сцеживалась'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Записать'));
      await tester.pumpAndSettle();

      expect(find.text('Записано: сцеживание, 100 мл'), findsOneWidget);

      // Let the confirmation go: it floats over the bottom of the screen,
      // which is where the next sheet's buttons are.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // And the day's total is there the next time she opens it.
      await tester.tap(find.widgetWithText(InkWell, 'Покормила'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Я сцеживалась'));
      await tester.pumpAndSettle();
      expect(find.text('Сегодня сцежено 100 мл'), findsOneWidget);
    });
  });
}
