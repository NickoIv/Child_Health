import 'package:child_health_tracker/core/care/daily_reflection.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/features/dashboard/reflection_card.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An evening card that counts and stops. What is tested is mostly the
/// stopping: not before evening, not on a thin day, not twice, and never with
/// a word about what any of the numbers mean.
void main() {
  setUpAll(initializeDateFormatting);

  final evening = DateTime(2026, 8, 2, 20);

  DevelopmentLog log(
    LogType type, {
    Duration ago = const Duration(hours: 1),
    int? minutes,
    NappyKind? nappy,
    double? temperature,
  }) => DevelopmentLog(
    id: '$type$ago$minutes$temperature',
    childId: 'demo',
    date: evening.subtract(ago),
    type: type,
    title: 'x',
    durationMinutes: minutes,
    nappyKind: nappy,
    metrics: Metrics(temperatureC: temperature),
  );

  /// A day with enough in it to be worth adding up.
  List<DevelopmentLog> aDay() => [
    log(LogType.feeding, ago: const Duration(hours: 10)),
    log(LogType.feeding, ago: const Duration(hours: 7)),
    log(LogType.feeding, ago: const Duration(hours: 3)),
    log(LogType.sleep, ago: const Duration(hours: 6), minutes: 90),
    log(LogType.sleep, ago: const Duration(hours: 2), minutes: 45),
    log(LogType.nappy, ago: const Duration(hours: 8), nappy: NappyKind.wet),
    log(LogType.nappy, ago: const Duration(hours: 4), nappy: NappyKind.both),
  ];

  group('when it appears', () {
    test('in the evening, on a day with something in it', () {
      final day = reflectionFor(aDay(), evening);

      expect(day, isNotNull);
      expect(day!.feedings, 3);
      expect(day.sleepMinutes, 135);
      expect(day.nappies, 2);
      expect(day.events, 7);
    });

    test('not before six — the day is still happening', () {
      expect(reflectionFor(aDay(), DateTime(2026, 8, 2, 17, 59)), isNull);
      expect(reflectionFor(aDay(), DateTime(2026, 8, 2, 18)), isNotNull);
    });

    test('not on a day with barely anything recorded', () {
      final thin = [
        log(LogType.feeding, ago: const Duration(hours: 2)),
        log(LogType.nappy, ago: const Duration(hours: 1), nappy: NappyKind.wet),
      ];
      expect(reflectionFor(thin, evening), isNull);

      // Three is the line.
      expect(
        reflectionFor(
          [...thin, log(LogType.sleep, minutes: 30)],
          evening,
        ),
        isNotNull,
      );
    });

    test('yesterday does not count towards today', () {
      final yesterday = [
        for (var i = 0; i < 5; i++)
          log(LogType.feeding, ago: Duration(hours: 24 + i)),
      ];
      expect(reflectionFor(yesterday, evening), isNull);
    });

    test('a temperature is carried as a fact, highest reading first', () {
      final withFever = [
        ...aDay(),
        log(LogType.illness, ago: const Duration(hours: 5), temperature: 37.4),
        log(LogType.illness, ago: const Duration(hours: 3), temperature: 38.2),
      ];
      final day = reflectionFor(withFever, evening)!;

      expect(day.hasTemperature, isTrue);
      expect(day.temperatureC, 38.2);
    });

    test('no reading means nothing to say about temperature', () {
      expect(reflectionFor(aDay(), evening)!.hasTemperature, isFalse);
    });
  });

  group('once a day', () {
    test('dismissing hides it for the rest of the evening', () {
      expect(
        reflectionFor(aDay(), evening, dismissedDay: evening),
        isNull,
      );
    });

    test('and tomorrow starts clean', () {
      final tomorrow = DateTime(2026, 8, 3, 20);
      final logs = [
        for (var i = 0; i < 4; i++)
          DevelopmentLog(
            id: 'x$i',
            childId: 'demo',
            date: tomorrow.subtract(Duration(hours: i + 1)),
            type: LogType.feeding,
            title: 'x',
          ),
      ];

      expect(
        reflectionFor(logs, tomorrow, dismissedDay: evening),
        isNotNull,
      );
    });
  });

  group('the card', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<void> pump(
      WidgetTester tester, {
      required List<DevelopmentLog> logs,
      DateTime? at,
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
            home: Scaffold(body: ReflectionCard(now: at ?? evening)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('takes no room when the day does not qualify', (tester) async {
      await pump(tester, logs: const []);

      expect(find.byType(Container), findsNothing);
      expect(tester.getSize(find.byType(ReflectionCard)).height, 0);
    });

    testWidgets('shows the counts and both blocks of text', (tester) async {
      await pump(tester, logs: aDay());
      final l = await AppLocalizations.delegate.load(defaultLocale);

      expect(find.text(l.reflectionTitle), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // feedings
      expect(find.text(l.countFeedings), findsOneWidget);
      expect(find.text(l.reflectionNappies), findsOneWidget);
      expect(find.text(l.reflectionSummary(3, '2 ч 15 мин')), findsOneWidget);
      expect(find.text(l.reflectionSupport), findsOneWidget);
    });

    testWidgets('states a temperature without commenting on it', (
      tester,
    ) async {
      await pump(tester, logs: [
        ...aDay(),
        log(LogType.illness, ago: const Duration(hours: 3), temperature: 38.2),
      ]);

      expect(find.textContaining('38.2'), findsOneWidget);
    });

    testWidgets('the cross puts it away', (tester) async {
      await pump(tester, logs: aDay());
      final l = await AppLocalizations.delegate.load(defaultLocale);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text(l.reflectionSupport), findsNothing);
    });

    testWidgets('it speaks whichever language the app is in', (tester) async {
      for (final locale in supportedLocales) {
        await pump(tester, logs: aDay(), locale: locale);
        final l = await AppLocalizations.delegate.load(locale);

        expect(
          find.text(l.reflectionSupport),
          findsOneWidget,
          reason: locale.languageCode,
        );
      }
    });
  });

  test('nothing in the wording reads as advice or a verdict', () async {
    // A guardrail on the copy: this card counts, and the moment it starts
    // telling a parent what her numbers mean it has become something else.
    const forbidden = [
      'норм', 'мало', 'много', 'следует', 'рекоменд', 'стоит', 'должн',
      'should', 'recommend', 'too few', 'too many', 'normal',
      'керек', 'ұсын',
    ];

    for (final locale in supportedLocales) {
      final l = await AppLocalizations.delegate.load(locale);
      final copy = [
        l.reflectionTitle,
        l.reflectionSummary(8, '5 h'),
        l.reflectionSupport,
        l.reflectionNappies,
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
