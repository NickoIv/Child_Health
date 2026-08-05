import 'package:child_health_tracker/core/care/patterns.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/features/dashboard/pattern_card.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Observations about a child's own recent days. Most of what is tested is
/// the silence: fewer than three days, days that do not agree, and any hint
/// of a norm creeping into the wording.
void main() {
  setUpAll(initializeDateFormatting);

  final today = DateTime(2026, 8, 2, 19);

  DevelopmentLog entry(
    LogType type, {
    required DateTime at,
    int? minutes,
    int? wakings,
  }) => DevelopmentLog(
    id: '$type$at$minutes',
    childId: 'demo',
    date: at,
    type: type,
    title: 'x',
    durationMinutes: minutes,
    nightWakings: wakings,
  );

  DateTime dayAgo(int days, int hour, [int minute = 0]) =>
      DateTime(2026, 8, 2 - days, hour, minute);

  /// A nap that ends at [wakeHour], and a feed [gap] minutes later.
  List<DevelopmentLog> napAndFeed(int days, {required int gap}) => [
    entry(LogType.sleep, at: dayAgo(days, 13), minutes: 60),
    entry(LogType.feeding, at: dayAgo(days, 14, gap)),
  ];

  group('a nap followed by a feed', () {
    test('is noticed once three days agree', () {
      final logs = [
        for (var d = 1; d <= 3; d++) ...napAndFeed(d, gap: 30),
      ];

      expect(patternFor(logs, today)?.kind, PatternKind.sleepThenFeeding);
    });

    test('two days is not a habit', () {
      final logs = [
        for (var d = 1; d <= 2; d++) ...napAndFeed(d, gap: 30),
      ];

      expect(patternFor(logs, today)?.kind, isNot(PatternKind.sleepThenFeeding));
    });

    test('a feed hours later says nothing about waking up', () {
      final logs = [
        for (var d = 1; d <= 4; d++) ...napAndFeed(d, gap: 180),
      ];

      expect(patternFor(logs, today)?.kind, isNot(PatternKind.sleepThenFeeding));
    });

    test('a night is not a nap', () {
      final logs = [
        for (var d = 1; d <= 4; d++) ...[
          entry(LogType.sleep, at: dayAgo(d, 21), minutes: 540, wakings: 1),
          entry(LogType.feeding, at: dayAgo(d, 21, 30)),
        ],
      ];

      expect(patternFor(logs, today)?.kind, isNot(PatternKind.sleepThenFeeding));
    });
  });

  group('the usual start of the night', () {
    test('three nights close together give a time', () {
      final logs = [
        entry(LogType.sleep, at: dayAgo(1, 21, 10), minutes: 540, wakings: 1),
        entry(LogType.sleep, at: dayAgo(2, 20, 50), minutes: 540, wakings: 1),
        entry(LogType.sleep, at: dayAgo(3, 21), minutes: 540, wakings: 1),
      ];

      final observation = patternFor(logs, today);
      expect(observation?.kind, PatternKind.nightStart);
      // Just past nine, which is where the three of them average.
      expect(observation!.nightStartMinutes, 21 * 60);
    });

    test('nights all over the place are not a habit', () {
      final logs = [
        entry(LogType.sleep, at: dayAgo(1, 19), minutes: 540, wakings: 1),
        entry(LogType.sleep, at: dayAgo(2, 21), minutes: 540, wakings: 1),
        entry(LogType.sleep, at: dayAgo(3, 23), minutes: 540, wakings: 1),
      ];

      expect(patternFor(logs, today)?.kind, isNot(PatternKind.nightStart));
    });

    test('a night begun after midnight is late, not early', () {
      // 23:40, 00:10 and 23:50 are half an hour apart, not twenty-four.
      final logs = [
        entry(LogType.sleep, at: dayAgo(1, 23, 40), minutes: 500, wakings: 1),
        entry(LogType.sleep, at: dayAgo(2, 0, 10), minutes: 500, wakings: 1),
        entry(LogType.sleep, at: dayAgo(3, 23, 50), minutes: 500, wakings: 1),
      ];

      final observation = patternFor(logs, today);
      expect(observation?.kind, PatternKind.nightStart);
      expect(observation!.nightStartMinutes, greaterThan(23 * 60));
    });
  });

  group('sleep that stays about the same', () {
    test('totals within an hour of each other', () {
      final logs = [
        for (var d = 1; d <= 3; d++)
          entry(LogType.sleep, at: dayAgo(d, 13), minutes: 600 + d * 10),
      ];

      expect(patternFor(logs, today)?.kind, PatternKind.stableSleep);
    });

    test('a swing of hours is not "about the same"', () {
      final logs = [
        entry(LogType.sleep, at: dayAgo(1, 13), minutes: 600),
        entry(LogType.sleep, at: dayAgo(2, 13), minutes: 400),
        entry(LogType.sleep, at: dayAgo(3, 13), minutes: 700),
      ];

      expect(patternFor(logs, today), isNull);
    });

    test('days with no sleep recorded are gaps, not zeroes', () {
      final logs = [
        entry(LogType.sleep, at: dayAgo(1, 13), minutes: 600),
        entry(LogType.sleep, at: dayAgo(2, 13), minutes: 610),
        entry(LogType.feeding, at: dayAgo(3, 13)),
      ];

      // Two totals and a silent day is not three days of steady sleep.
      expect(patternFor(logs, today), isNull);
    });
  });

  group('the rules that hold it back', () {
    test('nothing at all before three days of data', () {
      final logs = [
        for (var d = 1; d <= 2; d++)
          entry(LogType.sleep, at: dayAgo(d, 13), minutes: 600),
      ];

      expect(patternFor(logs, today), isNull);
    });

    test('one observation at a time, the nap pairing first', () {
      final logs = [
        for (var d = 1; d <= 3; d++) ...[
          ...napAndFeed(d, gap: 30),
          entry(LogType.sleep, at: dayAgo(d, 21), minutes: 540, wakings: 1),
        ],
      ];

      expect(patternFor(logs, today)?.kind, PatternKind.sleepThenFeeding);
    });

    test('today is not counted, so it does not shift during the day', () {
      final logs = [
        for (var d = 1; d <= 3; d++) ...napAndFeed(d, gap: 30),
      ];

      final morning = patternFor(logs, DateTime(2026, 8, 2, 8))?.kind;
      final night = patternFor(logs, DateTime(2026, 8, 2, 23))?.kind;
      expect(morning, night);
    });

    test('dismissing hides it until tomorrow', () {
      final logs = [
        for (var d = 1; d <= 3; d++) ...napAndFeed(d, gap: 30),
      ];

      expect(patternFor(logs, today, dismissedDay: today), isNull);
      // A new day, and the same history speaks again.
      expect(
        patternFor(
          logs,
          today.add(const Duration(days: 1)),
          dismissedDay: today,
        ),
        isNotNull,
      );
    });
  });

  group('the card', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<void> pump(
      WidgetTester tester, {
      required List<DevelopmentLog> logs,
      Locale locale = defaultLocale,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            logsProvider.overrideWith((ref) => Stream.value(logs)),
          ],
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: supportedLocales,
            home: Scaffold(body: PatternCard(now: today)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('takes no room when there is nothing to observe', (
      tester,
    ) async {
      await pump(tester, logs: const []);
      expect(tester.getSize(find.byType(PatternCard)).height, 0);
    });

    testWidgets('shows the observation and can be closed', (tester) async {
      final l = await AppLocalizations.delegate.load(defaultLocale);
      await pump(tester, logs: [
        for (var d = 1; d <= 3; d++) ...napAndFeed(d, gap: 30),
      ]);

      expect(find.text(l.patternSleepThenFeeding), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text(l.patternSleepThenFeeding), findsNothing);
    });

    testWidgets('the bedtime is written as a clock time', (tester) async {
      await pump(tester, logs: [
        entry(LogType.sleep, at: dayAgo(1, 21, 10), minutes: 540, wakings: 1),
        entry(LogType.sleep, at: dayAgo(2, 20, 50), minutes: 540, wakings: 1),
        entry(LogType.sleep, at: dayAgo(3, 21), minutes: 540, wakings: 1),
      ]);

      expect(find.textContaining('21:00'), findsOneWidget);
    });

    testWidgets('it speaks whichever language the app is in', (tester) async {
      for (final locale in supportedLocales) {
        final l = await AppLocalizations.delegate.load(locale);
        await pump(
          tester,
          logs: [for (var d = 1; d <= 3; d++) ...napAndFeed(d, gap: 30)],
          locale: locale,
        );

        expect(
          find.text(l.patternSleepThenFeeding),
          findsOneWidget,
          reason: locale.languageCode,
        );
      }
    });
  });

  test('nothing in the wording is a norm, a verdict or advice', () async {
    const forbidden = [
      'норм', 'мало', 'много', 'следует', 'рекоменд', 'стоит', 'должн',
      'лучше', 'правильн',
      'should', 'recommend', 'normal', 'too few', 'too many', 'better',
      'керек', 'ұсын', 'дұрыс',
    ];

    for (final locale in supportedLocales) {
      final l = await AppLocalizations.delegate.load(locale);
      final copy = [
        l.patternSleepThenFeeding,
        l.patternNightStart('21:00'),
        l.patternStableSleep,
      ].join(' ').toLowerCase();

      for (final word in forbidden) {
        expect(
          copy.contains(word),
          isFalse,
          reason: '«$word» in ${locale.languageCode}',
        );
      }
    }
  });
}
