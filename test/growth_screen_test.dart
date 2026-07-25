import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/data/repositories.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FixedChildRepository implements ChildRepository {
  _FixedChildRepository(this.child);

  final Child child;

  @override
  Stream<List<Child>> watchChildren(String parentUid) =>
      Stream.value([child]);

  @override
  Future<Child> add({
    required String parentUid,
    required String name,
    required DateTime birthDate,
    required Gender gender,
  }) async => child;

  @override
  Future<void> update(Child child) async {}

  @override
  Future<void> delete(String childId) async {}
}

class _FixedLogRepository implements DevelopmentLogRepository {
  _FixedLogRepository(this.logs);

  final List<DevelopmentLog> logs;

  @override
  Stream<List<DevelopmentLog>> watchLogs(String childId) =>
      Stream.value(logs);

  @override
  Future<DevelopmentLog> add(DevelopmentLog log) async => log;

  @override
  Future<void> update(DevelopmentLog log) async {}

  @override
  Future<void> delete(String logId) async {}
}

void main() {
  setUpAll(() => initializeDateFormatting('ru_RU'));

  Future<void> pumpGrowth(
    WidgetTester tester, {
    required Child child,
    required List<DevelopmentLog> logs,
  }) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          childRepositoryProvider.overrideWithValue(
            _FixedChildRepository(child),
          ),
          logRepositoryProvider.overrideWithValue(_FixedLogRepository(logs)),
        ],
        child: const ChildHealthApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.show_chart_outlined).first);
    await tester.pumpAndSettle();
  }

  DevelopmentLog measurement(String id, DateTime date, double kg, double cm) =>
      DevelopmentLog(
        id: id,
        childId: 'c1',
        date: date,
        type: LogType.measurement,
        title: 'Измерение',
        metrics: Metrics(weightKg: kg, heightCm: cm),
      );

  testWidgets('plots a toddler inside the WHO reference range', (tester) async {
    final now = DateTime.now();
    final child = Child(
      id: 'c1',
      parentUid: 'p1',
      name: 'Малыш',
      birthDate: DateTime(now.year - 1, now.month, now.day),
      gender: Gender.male,
    );

    await pumpGrowth(
      tester,
      child: child,
      logs: [
        measurement('m1', now.subtract(const Duration(days: 180)), 8.0, 68.0),
        measurement('m2', now, 9.8, 76.0),
      ],
    );

    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('Нет измерений для построения графика'), findsNothing);
    expect(find.text('медиана ВОЗ'), findsOneWidget);
    expect(find.text('перцентиль'), findsOneWidget);
  });

  testWidgets('still plots a child older than the reference tables', (
    tester,
  ) async {
    // Regression: the x-axis used to be clamped to 60 months, so every
    // measurement for a school-age child fell outside the chart and the
    // graph came up blank.
    final now = DateTime.now();
    final child = Child(
      id: 'c1',
      parentUid: 'p1',
      name: 'Школьник',
      birthDate: DateTime(now.year - 8, now.month, now.day),
      gender: Gender.male,
    );

    await pumpGrowth(
      tester,
      child: child,
      logs: [
        measurement('m1', now.subtract(const Duration(days: 365)), 24.0, 122.0),
        measurement('m2', now, 27.5, 129.0),
      ],
    );

    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('Нет измерений для построения графика'), findsNothing);

    // The reference curves still cover 0-60 months, so the legend belongs
    // there — but the chart says plainly where they stop.
    expect(find.text('медиана ВОЗ'), findsOneWidget);
    expect(
      find.textContaining('обрываются на 60 месяцах'),
      findsOneWidget,
    );
    expect(
      find.textContaining('вне диапазона справочных таблиц'),
      findsOneWidget,
    );
  });

  testWidgets('shows the empty state when there are no measurements', (
    tester,
  ) async {
    final now = DateTime.now();
    final child = Child(
      id: 'c1',
      parentUid: 'p1',
      name: 'Малыш',
      birthDate: DateTime(now.year - 1, now.month, now.day),
      gender: Gender.male,
    );

    await pumpGrowth(tester, child: child, logs: const []);

    expect(find.text('Нет измерений для построения графика'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
  });
}
