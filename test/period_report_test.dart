import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/features/reports/period_report.dart';
import 'package:child_health_tracker/features/reports/period_report_pdf.dart';
import 'package:child_health_tracker/features/reports/report_share.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// A period of counting, handed to a doctor. What is tested is that the
/// arithmetic is right, that the window is exactly the window, and that
/// nothing in the document interprets any of it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeDateFormatting);

  final now = DateTime(2026, 8, 2, 20);

  final child = Child(
    id: 'c1',
    parentUid: 'p1',
    name: 'Aisha',
    birthDate: DateTime(2025, 8, 2),
    gender: Gender.female,
  );

  DevelopmentLog log(
    LogType type, {
    required Duration ago,
    int? minutes,
    int? wakings,
    FeedingSide? side,
    NappyKind? nappy,
    double? temperature,
    String title = 'x',
    String description = '',
  }) => DevelopmentLog(
    id: '$type$ago$minutes$temperature$description',
    childId: 'c1',
    date: now.subtract(ago),
    type: type,
    title: title,
    description: description,
    durationMinutes: minutes,
    nightWakings: wakings,
    feedingSide: side,
    nappyKind: nappy,
    metrics: Metrics(temperatureC: temperature),
  );

  List<DevelopmentLog> aWeek() => [
    // Three nights: 9h/1 waking, 8h/3, 10h/2.
    log(LogType.sleep, ago: const Duration(hours: 23), minutes: 540,
        wakings: 1),
    log(LogType.sleep, ago: const Duration(days: 1, hours: 23), minutes: 480,
        wakings: 3),
    log(LogType.sleep, ago: const Duration(days: 2, hours: 23), minutes: 600,
        wakings: 2),
    // Naps on two days: 90 + 30 on one, 60 on the other.
    log(LogType.sleep, ago: const Duration(hours: 6), minutes: 90),
    log(LogType.sleep, ago: const Duration(hours: 9), minutes: 30),
    log(LogType.sleep, ago: const Duration(days: 1, hours: 6), minutes: 60),
    // Feeds: two breast, one bottle.
    log(LogType.feeding, ago: const Duration(hours: 2),
        side: FeedingSide.left),
    log(LogType.feeding, ago: const Duration(hours: 5),
        side: FeedingSide.right),
    log(LogType.feeding, ago: const Duration(hours: 8),
        side: FeedingSide.bottle),
    // Nappies, one of each.
    log(LogType.nappy, ago: const Duration(hours: 3), nappy: NappyKind.wet),
    log(LogType.nappy, ago: const Duration(hours: 7), nappy: NappyKind.dirty),
    log(LogType.nappy, ago: const Duration(hours: 11), nappy: NappyKind.both),
    // Temperature, twice.
    log(LogType.illness, ago: const Duration(hours: 4), temperature: 38.4),
    log(LogType.measurement, ago: const Duration(days: 1), temperature: 36.8),
    // A dose and a note.
    log(LogType.note, ago: const Duration(hours: 4, minutes: 30),
        title: LogTitles.medicine, description: 'Нурофен 2.5 мл'),
    log(LogType.note, ago: const Duration(hours: 12),
        title: 'Заметка', description: 'Улыбался весь день'),
  ];

  /// The same week, hung on the real clock instead of on [now].
  ///
  /// The arithmetic tests hand `buildPeriodReport` the date they were written
  /// for; the widget flow cannot — it goes through the screen, and the screen
  /// asks the machine what day it is. A fixture pinned to a date is therefore
  /// «the last seven days» for one week and an empty report ever after, which
  /// is exactly how this test spent a week failing.
  List<DevelopmentLog> aWeekFromToday() {
    final shift = DateTime.now().difference(now);
    return [
      for (final l in aWeek()) l.copyWith(date: l.date.add(shift)),
    ];
  }

  group('the arithmetic', () {
    test('sleep is averaged per night and per day', () {
      final r = buildPeriodReport(child, aWeek(), ReportPeriod.week, now: now);

      expect(r.nights, 3);
      expect(r.averageNightMinutes, 540); // (540 + 480 + 600) / 3
      expect(r.averageWakings, 2); // (1 + 3 + 2) / 3
      // Naps are summed per day, then averaged over the days that had any.
      expect(r.daysWithNaps, 2);
      expect(r.averageDayNapMinutes, 90); // (120 + 60) / 2
    });

    test('feeds are split by how they were given', () {
      final r = buildPeriodReport(child, aWeek(), ReportPeriod.week, now: now);

      expect(r.feedings, 3);
      expect(r.breastFeedings, 2);
      expect(r.bottleFeedings, 1);
    });

    test('nappies are counted by kind', () {
      final r = buildPeriodReport(child, aWeek(), ReportPeriod.week, now: now);

      expect(r.wetNappies, 1);
      expect(r.dirtyNappies, 1);
      expect(r.bothNappies, 1);
    });

    test('temperature keeps both ends and the count', () {
      final r = buildPeriodReport(child, aWeek(), ReportPeriod.week, now: now);

      expect(r.temperatureCount, 2);
      expect(r.maxTemperature, 38.4);
      expect(r.minTemperature, 36.8);
    });

    test('doses and notes are listed with their times', () {
      final r = buildPeriodReport(child, aWeek(), ReportPeriod.week, now: now);

      expect(r.medicines.single.text, 'Нурофен 2.5 мл');
      expect(r.notes.single.text, 'Улыбался весь день');
      expect(r.medicines.single.at.hour, 15);
    });

    test('only the last five notes make it', () {
      final many = [
        for (var i = 0; i < 9; i++)
          log(LogType.note, ago: Duration(hours: i + 1),
              title: 'Заметка', description: 'note $i'),
      ];
      final r = buildPeriodReport(child, many, ReportPeriod.week, now: now);

      expect(r.notes.length, 5);
      // Newest first: the ones a doctor is asked about.
      expect(r.notes.first.text, 'note 0');
    });
  });

  group('the window', () {
    test('a week means seven days, and the eighth is outside it', () {
      final logs = [
        log(LogType.feeding, ago: const Duration(days: 6),
            side: FeedingSide.left),
        log(LogType.feeding, ago: const Duration(days: 8),
            side: FeedingSide.left),
      ];

      expect(
        buildPeriodReport(child, logs, ReportPeriod.week, now: now).feedings,
        1,
      );
      expect(
        buildPeriodReport(child, logs, ReportPeriod.month, now: now).feedings,
        2,
      );
    });

    test('each period covers what it says', () {
      expect(ReportPeriod.week.days, 7);
      expect(ReportPeriod.twoWeeks.days, 14);
      expect(ReportPeriod.month.days, 30);
    });

    test('an empty period says so rather than printing blank sections', () {
      final r = buildPeriodReport(child, const [], ReportPeriod.week, now: now);

      expect(r.isEmpty, isTrue);
      expect(r.hasSleep, isFalse);
      expect(r.hasFeeding, isFalse);
      expect(r.hasTemperature, isFalse);
    });

    test('a section with nothing in it is not claimed', () {
      final onlyFeeds = [
        log(LogType.feeding, ago: const Duration(hours: 1),
            side: FeedingSide.left),
      ];
      final r = buildPeriodReport(child, onlyFeeds, ReportPeriod.week,
          now: now);

      expect(r.hasFeeding, isTrue);
      expect(r.hasSleep, isFalse);
      expect(r.hasNappies, isFalse);
      expect(r.hasNotes, isFalse);
    });
  });

  group('the document', () {
    for (final locale in supportedLocales) {
      testWidgets('${locale.languageCode} renders a real PDF', (tester) async {
        final l = await AppLocalizations.delegate.load(locale);
        final report =
            buildPeriodReport(child, aWeek(), ReportPeriod.twoWeeks, now: now);

        final bytes = await renderPeriodReport(
          report,
          l,
          localeName: locale.languageCode,
        );

        // A PDF, and one with pages in it rather than an empty shell.
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
        expect(bytes.length, greaterThan(2000));
      });
    }

    test('every label the document prints exists in all three languages',
        () async {
      for (final locale in supportedLocales) {
        final l = await AppLocalizations.delegate.load(locale);

        for (final label in [
          l.reportTitle,
          l.reportExport,
          l.reportPeriod,
          l.reportSectionSleep,
          l.reportAvgNight,
          l.reportAvgDay,
          l.reportAvgWakings,
          l.reportSectionFeeding,
          l.reportFeedingsTotal,
          l.reportBreast,
          l.reportBottle,
          l.reportSectionNappies,
          l.reportSectionTemperature,
          l.reportTempMax,
          l.reportTempMin,
          l.reportTempCount,
          l.reportSectionMedicines,
          l.reportSectionNotes,
          l.reportDisclaimer,
          l.reportPeriodDays(7),
          l.reportPage(1, 2),
        ]) {
          expect(label.trim(), isNotEmpty, reason: locale.languageCode);
        }
      }
    });

    test('the disclaimer is exactly the sentence it has to be', () async {
      final ru = await AppLocalizations.delegate.load(const Locale('ru'));
      expect(
        ru.reportDisclaimer,
        'Отчёт предназначен для удобства обсуждения с врачом и не является '
        'медицинским заключением.',
      );

      final en = await AppLocalizations.delegate.load(const Locale('en'));
      expect(
        en.reportDisclaimer,
        'This report is intended to support discussion with a doctor and is '
        'not a medical conclusion.',
      );
    });

    test('nothing in the wording interprets, advises or compares', () async {
      // The document counts. The moment it starts telling a doctor what the
      // numbers mean it has stopped being a record and started being an
      // opinion the app is in no position to hold.
      const forbidden = [
        'норм', 'мало', 'много', 'рекоменд', 'следует', 'перцентил',
        'отклонен', 'вывод', 'диагноз',
        'normal', 'recommend', 'percentile', 'deviation', 'conclusion',
        'should', 'too few', 'too many',
      ];

      for (final locale in supportedLocales) {
        final l = await AppLocalizations.delegate.load(locale);
        final copy = [
          l.reportTitle,
          l.reportSectionSleep,
          l.reportAvgNight,
          l.reportAvgDay,
          l.reportAvgWakings,
          l.reportSectionFeeding,
          l.reportFeedingsTotal,
          l.reportSectionNappies,
          l.reportSectionTemperature,
          l.reportTempMax,
          l.reportTempMin,
          l.reportSectionMedicines,
          l.reportSectionNotes,
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
  });

  group('the handover', () {
    // What the platform was asked to share, captured off the channel the
    // printing plugin talks to. On a phone the native side writes this into
    // the app's cache directory and opens the system sheet over it; in a
    // browser the same bytes become a download. Neither leaves the device,
    // and this test is the seam where that stays true.
    late List<Map<Object?, Object?>> shared;

    setUp(() {
      shared = [];
      TestDefaultBinaryMessengerBinding
          .instance
          .defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('net.nfet.printing'),
            (call) async {
              if (call.method == 'sharePdf') {
                shared.add(call.arguments as Map<Object?, Object?>);
                return 1;
              }
              return null;
            },
          );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding
          .instance
          .defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('net.nfet.printing'),
            null,
          );
    });

    test('a name a temporary file can be called survives it', () {
      expect(reportFilename('Aisha', 7), 'report_Aisha_7d.pdf');
      // Spaces and slashes would break the file the share sheet opens over.
      expect(reportFilename('Аня Петрова', 14), 'report_Аня_Петрова_14d.pdf');
      expect(reportFilename('a/b:c', 30), 'report_a_b_c_30d.pdf');
      expect(reportFilename('   ', 7), 'report_7d.pdf');
    });

    testWidgets('a tap says it is working, says it is ready, and shares', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            childrenProvider.overrideWith((ref) => Stream.value([child])),
            // The screen reads the machine's clock, so the week has to be the
            // one the machine is in. See [aWeekFromToday].
            logsProvider.overrideWith((ref) => Stream.value(aWeekFromToday())),
          ],
          child: const ChildHealthApp(),
        ),
      );
      await tester.pumpAndSettle();

      final l = await AppLocalizations.delegate.load(defaultLocale);
      await tester.tap(find.text(l.navMedical).last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, l.reportExport));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l.reportPeriodDays(7)));
      await tester.pump();

      // The one slow moment in the whole flow is named rather than blank.
      expect(find.text(l.reportPreparing), findsOneWidget);

      await tester.pumpAndSettle();

      // The sheet is gone, the confirmation is up, and the file went out.
      expect(find.text(l.reportPeriodDays(7)), findsNothing);
      expect(find.text(l.reportReady), findsOneWidget);

      expect(shared, hasLength(1));
      expect(shared.single['name'], 'report_Aisha_7d.pdf');
      expect((shared.single['doc']! as Uint8List).length, greaterThan(2000));
    });

    testWidgets('an empty period is refused before anything is shared', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            childrenProvider.overrideWith((ref) => Stream.value([child])),
            logsProvider.overrideWith(
              (ref) => Stream.value(const <DevelopmentLog>[]),
            ),
          ],
          child: const ChildHealthApp(),
        ),
      );
      await tester.pumpAndSettle();

      final l = await AppLocalizations.delegate.load(defaultLocale);
      await tester.tap(find.text(l.navMedical).last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, l.reportExport));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l.reportPeriodDays(7)));
      await tester.pumpAndSettle();

      expect(find.text(l.reportNothing), findsOneWidget);
      expect(find.text(l.reportPreparing), findsNothing);
      expect(shared, isEmpty);
    });

    test('all three languages have something to say at every step', () async {
      for (final locale in supportedLocales) {
        final l = await AppLocalizations.delegate.load(locale);

        for (final message in [
          l.reportPreparing,
          l.reportReady,
          l.reportShareFailed,
        ]) {
          expect(message.trim(), isNotEmpty, reason: locale.languageCode);
        }
      }
    });

    test('the Russian wording is the wording asked for', () async {
      final ru = await AppLocalizations.delegate.load(const Locale('ru'));
      expect(ru.reportPreparing, 'Готовим PDF…');
      expect(ru.reportReady, 'Отчёт готов');
    });
  });

  testWidgets('the medical screen offers the export and asks for a period', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          childrenProvider.overrideWith((ref) => Stream.value([child])),
          logsProvider.overrideWith((ref) => Stream.value(aWeek())),
        ],
        child: const ChildHealthApp(),
      ),
    );
    await tester.pumpAndSettle();

    final l = await AppLocalizations.delegate.load(defaultLocale);
    await tester.tap(find.text(l.navMedical).last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, l.reportExport));
    await tester.pumpAndSettle();

    // Three periods, and nothing else to decide.
    for (final period in ReportPeriod.values) {
      expect(
        find.text(l.reportPeriodDays(period.days)),
        findsOneWidget,
        reason: '${period.days} days',
      );
    }
  });
}
