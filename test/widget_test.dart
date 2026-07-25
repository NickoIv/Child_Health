import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/features/dashboard/dashboard_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ru_RU'));

  Future<void> pumpApp(WidgetTester tester) async {
    // The default 800x600 surface is too short for the dashboard: its ListView
    // builds lazily, so the lower cards would never be laid out. A tall
    // viewport also puts the shell into its wide (navigation rail) layout.
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: ChildHealthApp()));
    await tester.pumpAndSettle();
  }

  testWidgets('boots to the dashboard with the seeded child', (tester) async {
    await pumpApp(tester);

    // "Обзор" legitimately appears twice — as the AppBar title and as the
    // navigation label — so anchor the assertion to the AppBar.
    expect(find.widgetWithText(AppBar, 'Обзор'), findsOneWidget);
    expect(find.text('Демо-профиль'), findsWidgets);
  });

  testWidgets('dashboard renders every configured widget', (tester) async {
    await pumpApp(tester);

    // The summary card is titled with the child's name, so check the rest by
    // their own headings.
    for (final title in const [
      'Рост и вес',
      'Ближайшие прививки',
      'Заболеваемость',
      'Последние записи',
      'Ближайшие события',
    ]) {
      expect(
        find.text(title),
        findsWidgets,
        reason: 'dashboard should show "$title"',
      );
    }
  });

  testWidgets('navigating to the diary shows the entry feed', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.auto_stories_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Лента событий'), findsOneWidget);
    expect(find.text('Первое слово'), findsOneWidget);
  });

  testWidgets('growth screen plots the WHO assessment', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.show_chart_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Динамика показателей'), findsOneWidget);
    expect(find.text('Оценка по нормам ВОЗ'), findsOneWidget);
    expect(find.text('перцентиль'), findsOneWidget);
  });

  testWidgets('diary filter narrows the feed to one type', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.auto_stories_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Первое слово'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Болезнь'));
    await tester.pumpAndSettle();

    // Milestones are filtered out, illness entries remain.
    expect(find.text('Первое слово'), findsNothing);
    expect(find.text('ОРВИ'), findsWidgets);
  });

  group('DashboardLayout', () {
    test('starts with every widget visible', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(dashboardLayoutProvider),
        DashboardWidgetKind.values,
      );
    });

    test('toggle hides and restores a widget', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(dashboardLayoutProvider.notifier);

      notifier.toggle(DashboardWidgetKind.illness);
      expect(
        container.read(dashboardLayoutProvider),
        isNot(contains(DashboardWidgetKind.illness)),
      );

      notifier.toggle(DashboardWidgetKind.illness);
      expect(
        container.read(dashboardLayoutProvider),
        contains(DashboardWidgetKind.illness),
      );
    });

    test('reorder moves a widget to the requested position', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(dashboardLayoutProvider.notifier);
      final first = container.read(dashboardLayoutProvider).first;

      // onReorderItem passes the final index, so moving item 0 to index 2
      // must land it exactly there.
      notifier.reorder(0, 2);
      expect(container.read(dashboardLayoutProvider)[2], first);
    });

    test('reset restores the default set', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(dashboardLayoutProvider.notifier);

      notifier.toggle(DashboardWidgetKind.growth);
      notifier.reorder(0, 3);
      notifier.reset();

      expect(
        container.read(dashboardLayoutProvider),
        DashboardWidgetKind.values,
      );
    });
  });
}
