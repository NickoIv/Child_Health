import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/features/assistant/context_block.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// The five facts a question about a child tends to start with, gathered from
/// entries she has already made. Nothing is concluded from them here, and
/// nothing leaves the device.
void main() {
  setUpAll(initializeDateFormatting);

  final now = DateTime(2026, 8, 2, 16);

  DevelopmentLog log(
    LogType type, {
    required Duration ago,
    int? minutes,
    int? wakings,
    double? temperature,
  }) => DevelopmentLog(
    id: '$type$ago$minutes$temperature',
    childId: 'demo',
    date: now.subtract(ago),
    type: type,
    title: 'x',
    durationMinutes: minutes,
    nightWakings: wakings,
    metrics: Metrics(temperatureC: temperature),
  );

  Future<void> pump(
    WidgetTester tester, {
    required List<DevelopmentLog> logs,
    Locale locale = defaultLocale,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [logsProvider.overrideWith((ref) => Stream.value(logs))],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: supportedLocales,
          home: Scaffold(body: ChildContextBlock(now: now)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('every line is present, and labelled', (tester) async {
    await pump(tester, logs: const []);
    final l = await AppLocalizations.delegate.load(defaultLocale);

    expect(find.text(l.contextTitle), findsOneWidget);
    for (final label in [
      l.commonAge,
      l.nowLastFeeding,
      l.nowLastSleep,
      l.quickNightSleep,
      l.quickSheetTemperature,
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('a feed shows its clock time and how long ago', (tester) async {
    await pump(tester, logs: [
      log(LogType.feeding, ago: const Duration(hours: 2)),
    ]);

    // 14:00, two hours before the pinned "now".
    expect(find.textContaining('14:00'), findsOneWidget);
    expect(find.textContaining('2 ч'), findsWidgets);
  });

  testWidgets('a nap shows when it was and how long it ran', (tester) async {
    await pump(tester, logs: [
      log(LogType.sleep, ago: const Duration(hours: 3), minutes: 90),
    ]);

    expect(find.textContaining('13:00'), findsOneWidget);
    expect(find.textContaining('1 ч 30 мин'), findsWidgets);
  });

  testWidgets('the night is reported by its length, not its clock', (
    tester,
  ) async {
    await pump(tester, logs: [
      log(LogType.sleep, ago: const Duration(hours: 19), minutes: 540,
          wakings: 2),
    ]);

    expect(find.textContaining('9 ч'), findsWidgets);
  });

  testWidgets('a night is not mistaken for the last nap', (tester) async {
    final l = await AppLocalizations.delegate.load(defaultLocale);
    await pump(tester, logs: [
      log(LogType.sleep, ago: const Duration(hours: 19), minutes: 540,
          wakings: 2),
    ]);

    // Nothing has been recorded as a daytime sleep, so that line says so.
    expect(find.text(l.nowNothingYet), findsWidgets);
  });

  group('temperature', () {
    testWidgets('says plainly when none was taken today', (tester) async {
      final l = await AppLocalizations.delegate.load(defaultLocale);
      await pump(tester, logs: [
        log(LogType.feeding, ago: const Duration(hours: 1)),
      ]);

      expect(find.text(l.contextNotRecorded), findsOneWidget);
    });

    testWidgets('shows the last reading of the day', (tester) async {
      await pump(tester, logs: [
        log(LogType.illness, ago: const Duration(hours: 6), temperature: 38.4),
        log(LogType.illness, ago: const Duration(hours: 1), temperature: 37.2),
      ]);

      // The latest, not the highest: this is a report, not an assessment.
      expect(find.textContaining('37.2'), findsOneWidget);
      expect(find.textContaining('38.4'), findsNothing);
    });

    testWidgets('yesterday does not count as today', (tester) async {
      final l = await AppLocalizations.delegate.load(defaultLocale);
      await pump(tester, logs: [
        log(LogType.illness, ago: const Duration(hours: 30), temperature: 38.4),
      ]);

      expect(find.text(l.contextNotRecorded), findsOneWidget);
    });
  });

  testWidgets('it speaks whichever language the app is in', (tester) async {
    for (final locale in supportedLocales) {
      await pump(
        tester,
        logs: [log(LogType.feeding, ago: const Duration(hours: 2))],
        locale: locale,
      );
      final l = await AppLocalizations.delegate.load(locale);

      expect(
        find.text(l.contextTitle),
        findsOneWidget,
        reason: locale.languageCode,
      );
      expect(find.text(l.nowLastFeeding), findsOneWidget);
    }
  });

  testWidgets('it stays compact on a phone', (tester) async {
    await pump(tester, logs: [
      log(LogType.feeding, ago: const Duration(hours: 2)),
      log(LogType.sleep, ago: const Duration(hours: 3), minutes: 90),
      log(LogType.sleep, ago: const Duration(hours: 19), minutes: 540,
          wakings: 2),
      log(LogType.illness, ago: const Duration(hours: 1), temperature: 37.2),
    ]);

    // Five lines and a heading, with room left for the search field beneath.
    final height = tester.getSize(find.byType(ChildContextBlock)).height;
    expect(height, lessThan(200));
  });

  testWidgets('without a child there is no context to show', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          childrenProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          locale: defaultLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: supportedLocales,
          home: Scaffold(body: ChildContextBlock(now: now)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(ChildContextBlock)).height, 0);
  });
}
