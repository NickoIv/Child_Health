import 'package:child_health_tracker/ai/child_snapshot.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/core/care/forecast_store.dart';
import 'package:child_health_tracker/core/care/sleep_forecast.dart';
import 'package:child_health_tracker/features/dashboard/sleep_forecast_card.dart';
import 'package:child_health_tracker/features/dashboard/smart_card.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The one thing in this app that talks about the next hour.
///
/// What is tested is the honesty of it: that the figure is the child's own
/// once there is enough of him to measure, that it says so when it is not,
/// and that it stays quiet in every case where a number would be a guess
/// dressed as a fact — asleep, too old, nothing written down, or a last nap so
/// stale it says nothing about this afternoon.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeDateFormatting);

  final now = DateTime(2026, 8, 9, 14, 30);

  Child childAged(int months) => Child(
    id: 'c1',
    parentUid: 'p1',
    name: 'Айша',
    birthDate: DateTime(now.year, now.month - months, now.day),
    gender: Gender.female,
  );

  DevelopmentLog sleep(DateTime at, int minutes) => DevelopmentLog(
    id: '$at$minutes',
    childId: 'c1',
    date: at,
    type: LogType.sleep,
    title: LogType.sleep.label,
    durationMinutes: minutes,
  );

  /// A fortnight of a child who is up for an hour and a half, twice a day.
  List<DevelopmentLog> fortnight({int gapMinutes = 90}) {
    final logs = <DevelopmentLog>[];
    for (var day = 1; day <= 7; day++) {
      final morning = DateTime(now.year, now.month, now.day - day, 9);
      logs.add(sleep(morning, 60));
      logs.add(sleep(morning.add(Duration(minutes: 60 + gapMinutes)), 60));
      logs.add(
        sleep(morning.add(Duration(minutes: 2 * (60 + gapMinutes))), 45),
      );
    }
    return logs.reversed.toList();
  }

  group('the wake window', () {
    test('is the age norm until there is enough of the child to measure', () {
      // Two gaps is not a habit.
      final thin = [
        sleep(now.subtract(const Duration(hours: 6)), 60),
        sleep(now.subtract(const Duration(hours: 3)), 60),
      ];
      final window = wakeWindowFor(thin, now, ageMonths: 5);
      expect(window.minutes, ageWakeWindowMinutes(5));
      expect(window.samples, lessThan(minForecastSamples));
    });

    test('becomes his own as soon as there are four of them', () {
      final window = wakeWindowFor(fortnight(), now, ageMonths: 5);
      // Ninety minutes, measured — against the two hours the table would have
      // given a five-month-old.
      expect(window.minutes, 90);
      expect(window.samples, greaterThanOrEqualTo(minForecastSamples));
      expect(ageWakeWindowMinutes(5), 120);
    });

    test('is a median, so one long car journey does not move the week', () {
      final logs = [
        ...fortnight(),
        // A four-hour drive through what should have been two naps.
        sleep(DateTime(now.year, now.month, now.day - 2, 8), 30),
        sleep(DateTime(now.year, now.month, now.day - 2, 12, 30), 30),
      ];
      expect(wakeWindowFor(logs, now, ageMonths: 5).minutes, 90);
    });

    test('widens with age, and the table is the ordinary one', () {
      expect(ageWakeWindowMinutes(0), lessThan(ageWakeWindowMinutes(3)));
      expect(ageWakeWindowMinutes(3), lessThan(ageWakeWindowMinutes(8)));
      expect(ageWakeWindowMinutes(8), lessThan(ageWakeWindowMinutes(20)));
      expect(ageWakeWindowMinutes(1), inInclusiveRange(45, 75));
      expect(ageWakeWindowMinutes(6), inInclusiveRange(120, 180));
    });
  });

  group('the forecast', () {
    test('is the last waking plus the window', () {
      final logs = [
        ...fortnight(),
        // Woke an hour ago from a nap that started an hour before that.
        sleep(now.subtract(const Duration(minutes: 120)), 60),
      ];

      final f = sleepForecastFor(logs, now, ageMonths: 5)!;
      expect(f.windowMinutes, 90);
      expect(f.awakeSince, now.subtract(const Duration(minutes: 60)));
      expect(f.expectedAt, now.add(const Duration(minutes: 30)));
      expect(f.awakeMinutesAt(now), 60);
      expect(f.personal, isTrue);
    });

    test('says nothing until the window is nearly over', () {
      final logs = [
        ...fortnight(),
        sleep(now.subtract(const Duration(minutes: 80)), 60),
      ];
      // Seventy minutes to go: a countdown nobody asked for.
      expect(sleepForecastFor(logs, now, ageMonths: 5), isNull);

      // Fifty minutes later it is worth saying.
      final later = now.add(const Duration(minutes: 50));
      final f = sleepForecastFor(logs, later, ageMonths: 5);
      expect(f, isNotNull);
      expect(f!.minutesLeftAt(later), lessThanOrEqualTo(forecastLeadMinutes));
      expect(f.isOverdueAt(later), isFalse);
    });

    test('stays a little past the estimate, then stops', () {
      final logs = [
        ...fortnight(),
        sleep(now.subtract(const Duration(minutes: 80)), 60),
      ];
      // Half an hour late: exactly when a parent wonders whether the crying
      // is tiredness.
      final late = now.add(const Duration(minutes: 100));
      expect(sleepForecastFor(logs, late, ageMonths: 5)?.isOverdueAt(late),
          isTrue);

      // Three hours late is not a late nap, it is a nap that was never
      // written down. Nothing to say about it.
      final stale = now.add(const Duration(hours: 4));
      expect(sleepForecastFor(logs, stale, ageMonths: 5), isNull);
    });

    test('is silent while he is asleep', () {
      final logs = [
        ...fortnight(),
        sleep(now.subtract(const Duration(minutes: 110)), 60),
      ];
      final moment = now.add(const Duration(minutes: 20));
      expect(sleepForecastFor(logs, moment, ageMonths: 5), isNotNull);
      // The clock is running on a nap, so there is nothing to predict.
      expect(
        sleepForecastFor(logs, moment, ageMonths: 5, asleep: true),
        isNull,
      );
    });

    test('is silent for a child too old for wake windows', () {
      final logs = [
        ...fortnight(),
        sleep(now.subtract(const Duration(minutes: 110)), 60),
      ];
      final moment = now.add(const Duration(minutes: 20));
      expect(sleepForecastFor(logs, moment, ageMonths: 40), isNull);
    });

    test('is silent with nothing written down, and with a sleep of no length',
        () {
      expect(sleepForecastFor(const [], now, ageMonths: 5), isNull);

      // «Поспал» with no minutes is a note that he slept, not a stretch that
      // ended at a knowable time.
      final vague = [
        DevelopmentLog(
          id: 'v',
          childId: 'c1',
          date: now.subtract(const Duration(hours: 2)),
          type: LogType.sleep,
          title: LogType.sleep.label,
        ),
      ];
      expect(sleepForecastFor(vague, now, ageMonths: 5), isNull);
    });
  });

  group('the card', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    final logs = [
      ...fortnight(),
      sleep(now.subtract(const Duration(minutes: 140)), 60),
    ];
    // Eighty minutes awake of a ninety-minute window: ten to go.
    final moment = now;

    Future<void> pump(WidgetTester tester, {DateTime? at}) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            childrenProvider.overrideWith(
              (ref) => Stream.value([childAged(5)]),
            ),
            logsProvider.overrideWith((ref) => Stream.value(logs)),
          ],
          child: MaterialApp(
            // Without this the test machine's own locale decides, and the card
            // comes up in English while the expectations are in Russian.
            locale: defaultLocale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SleepForecastCard(now: at ?? moment),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('prints the time, the window and where the number came from', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('СКОРО СОН'), findsOneWidget);
      // 13:10 woken + 90 minutes.
      expect(find.textContaining('14:40'), findsOneWidget);
      expect(find.textContaining('Не спит 1 ч 20 мин'), findsOneWidget);
      // Never a number without its source.
      expect(find.textContaining('По записям за две недели'), findsOneWidget);
    });

    testWidgets('says so when the figure is only the age table', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // One nap on record: nothing of his own to measure.
      final thin = [sleep(now.subtract(const Duration(minutes: 175)), 60)];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            childrenProvider.overrideWith(
              (ref) => Stream.value([childAged(5)]),
            ),
            logsProvider.overrideWith((ref) => Stream.value(thin)),
          ],
          child: MaterialApp(
            // Without this the test machine's own locale decides, and the card
            // comes up in English while the expectations are in Russian.
            locale: defaultLocale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: SleepForecastCard(now: now)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('возрастным нормам'), findsOneWidget);
    });

    testWidgets('closes under the finger and stays closed for the window', (
      tester,
    ) async {
      await pump(tester);
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('СКОРО СОН'), findsNothing);
      // And it is one window, not a suggestion's six hours.
      expect(forecastDismissDuration, const Duration(hours: 2));
    });

    testWidgets('offers the clock, which is the thing the app can do', (
      tester,
    ) async {
      await pump(tester);
      expect(find.widgetWithText(FilledButton, 'Засечь время'), findsOneWidget);
    });
  });

  group('what the assistant is told', () {
    test('includes the window, its source and the current stretch', () {
      final snapshot = childSnapshot(
        child: childAged(5),
        logs: [
          ...fortnight(),
          sleep(now.subtract(const Duration(minutes: 140)), 60),
        ],
        now: now,
      );

      expect(snapshot, contains('Окно бодрствования: ≈90 мин'));
      expect(snapshot, contains('промежуткам за 14 дней'));
      expect(snapshot, contains('Не спит с 13:10'));
      expect(snapshot, contains('14:40'));
    });

    test('does not claim a measurement it has not made', () {
      final snapshot = childSnapshot(
        child: childAged(5),
        logs: [sleep(now.subtract(const Duration(minutes: 140)), 60)],
        now: now,
      );
      expect(snapshot, contains('возрастным нормам'));
    });

    test('says nothing at all about a four-year-old', () {
      final snapshot = childSnapshot(
        child: childAged(48),
        logs: fortnight(),
        now: now,
      );
      expect(snapshot, isNot(contains('Окно бодрствования')));
    });
  });

  group('the one card the home screen shows', () {
    test('ranks the next hour above a shortcut and below a hard night', () {
      // The order is the claim: what someone said to her, then her night,
      // then the next hour, then everything that is merely useful.
      expect(
        SmartCardKind.values.indexOf(SmartCardKind.sleepForecast),
        greaterThan(SmartCardKind.values.indexOf(SmartCardKind.checkIn)),
      );
      expect(
        SmartCardKind.values.indexOf(SmartCardKind.sleepForecast),
        lessThan(SmartCardKind.values.indexOf(SmartCardKind.suggestion)),
      );
    });
  });
}
