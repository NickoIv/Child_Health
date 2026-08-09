import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/core/care/visit_prep.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/features/shared/widgets.dart';
import 'package:child_health_tracker/features/reports/period_report.dart';
import 'package:child_health_tracker/features/reports/period_report_pdf.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/models/medical_record.dart';
import 'package:child_health_tracker/models/reminder.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Getting ready for an appointment.
///
/// What is tested is that the screen is assembled out of entries that already
/// exist rather than out of a second list to keep up to date, that the period
/// it counts over is the one it names, and that the two things a doctor asks
/// for out loud — «на что была реакция» and «о чём вы хотели спросить» — reach
/// the sheet of paper that goes into the room.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeDateFormatting);

  final now = DateTime(2026, 8, 9, 12);

  final child = Child(
    id: 'c1',
    parentUid: 'p1',
    name: 'Aisha',
    birthDate: DateTime(2025, 11, 9),
    gender: Gender.female,
  );

  DevelopmentLog question(String text, {required Duration ago}) =>
      DevelopmentLog(
        id: 'q$text',
        childId: 'c1',
        date: now.subtract(ago),
        type: LogType.question,
        title: text,
      );

  DevelopmentLog measurement({required Duration ago, double weight = 8.4}) =>
      DevelopmentLog(
        id: 'm$ago',
        childId: 'c1',
        date: now.subtract(ago),
        type: LogType.measurement,
        title: 'x',
        metrics: Metrics(weightKg: weight, heightCm: 70),
      );

  DevelopmentLog medicine(String what, {required Duration ago}) =>
      DevelopmentLog(
        id: 'med$what$ago',
        childId: 'c1',
        date: now.subtract(ago),
        type: LogType.note,
        title: LogTitles.medicine,
        description: what,
      );

  DevelopmentLog spoon(String food, {required Duration ago}) => DevelopmentLog(
    id: 's$food$ago',
    childId: 'c1',
    date: now.subtract(ago),
    type: LogType.feeding,
    title: LogType.feeding.label,
    feedingSide: FeedingSide.solid,
    food: food,
  );

  DevelopmentLog reaction(
    String food,
    String what, {
    required Duration ago,
  }) => DevelopmentLog(
    id: 'r$food$ago',
    childId: 'c1',
    date: now.subtract(ago),
    type: LogType.note,
    title: LogTitles.reaction,
    description: what,
    food: food,
  );

  DevelopmentLog sickDay({required Duration ago, double? temperature}) =>
      DevelopmentLog(
        id: 'i$ago',
        childId: 'c1',
        date: now.subtract(ago),
        type: LogType.illness,
        title: 'x',
        severity: Severity.mild,
        metrics: Metrics(temperatureC: temperature),
      );

  Reminder dose(String title, {required Duration until, bool done = false}) =>
      Reminder(
        id: 'v$title',
        childId: 'c1',
        type: ReminderType.vaccination,
        title: title,
        scheduledTime: now.add(until),
        isCompleted: done,
      );

  MedicalRecord visit({required Duration ago}) => MedicalRecord(
    id: 'rec$ago',
    childId: 'c1',
    date: now.subtract(ago),
    diagnosis: 'Плановый осмотр',
  );

  VisitPrep prepOf({
    List<DevelopmentLog> logs = const [],
    List<Reminder> reminders = const [],
    List<MedicalRecord> records = const [],
  }) => buildVisitPrep(
    child: child,
    logs: logs,
    reminders: reminders,
    records: records,
    now: now,
  );

  group('the period it counts over', () {
    test('is the last appointment, and it says so', () {
      final prep = prepOf(records: [visit(ago: const Duration(days: 21))]);

      expect(prep.lastVisit, now.subtract(const Duration(days: 21)));
      expect(prep.daysCovered, 21);
    });

    test('falls back to a month when there has never been one', () {
      expect(prepOf().daysCovered, visitWindowDays);
    });

    test('never reaches further back than three months', () {
      // A visit last winter is not the period anyone is asking about, and a
      // year of medicines does not belong in a five-minute appointment.
      final prep = prepOf(records: [visit(ago: const Duration(days: 400))]);

      expect(prep.daysCovered, visitMaxWindowDays);
    });

    test('counts illness, temperature and medicines inside it and not '
        'outside', () {
      final prep = prepOf(
        logs: [
          sickDay(ago: const Duration(days: 3), temperature: 38.4),
          sickDay(ago: const Duration(days: 3), temperature: 37.9),
          sickDay(ago: const Duration(days: 2)),
          sickDay(ago: const Duration(days: 60), temperature: 39.5),
          medicine('Парацетамол 100 мг', ago: const Duration(days: 3)),
          medicine('Старое', ago: const Duration(days: 45)),
        ],
        records: [visit(ago: const Duration(days: 30))],
      );

      // Two calendar days, not four entries.
      expect(prep.sickDays, 2);
      expect(prep.maxTemperature, 38.4);
      expect(prep.medicines, hasLength(1));
      expect(prep.medicines.single.description, 'Парацетамол 100 мг');
      expect(prep.hasHistory, isTrue);
    });

    test('has nothing to say about a quiet month', () {
      expect(prepOf(logs: [measurement(ago: const Duration(days: 2))])
          .hasHistory, isFalse);
    });
  });

  group('the questions', () {
    test('come out oldest first, whatever the period is', () {
      // The one written five weeks ago and still unasked is exactly the one
      // worth carrying into the room.
      final prep = prepOf(
        logs: [
          question('Про сон', ago: const Duration(days: 2)),
          question('Про срыгивание', ago: const Duration(days: 40)),
        ],
        records: [visit(ago: const Duration(days: 7))],
      );

      expect(
        prep.questions.map((q) => q.title),
        ['Про срыгивание', 'Про сон'],
      );
      expect(prep.questionsState, PrepState.ready);
    });

    test('an empty list is not a failing grade', () {
      expect(prepOf().questionsState, PrepState.missing);
    });
  });

  group('the weight', () {
    test('is current a fortnight after it was taken', () {
      final prep = prepOf(logs: [measurement(ago: const Duration(days: 14))]);

      expect(prep.measurementAgeDays, 14);
      expect(prep.measurementIsStale, isFalse);
      expect(prep.measurementState, PrepState.ready);
    });

    test('is stale once a baby has gone more than a month unweighed', () {
      final prep = prepOf(logs: [measurement(ago: const Duration(days: 40))]);

      expect(prep.measurementState, PrepState.attention);
    });

    test('is given three months of slack past the first birthday', () {
      final toddler = Child(
        id: 'c1',
        parentUid: 'p1',
        name: 'Aisha',
        birthDate: DateTime(2024, 1, 1),
        gender: Gender.female,
      );
      final prep = buildVisitPrep(
        child: toddler,
        logs: [measurement(ago: const Duration(days: 40))],
        reminders: const [],
        records: const [],
        now: now,
      );

      expect(prep.measurementState, PrepState.ready);
    });

    test('a child never measured is missing rather than late', () {
      expect(prepOf().measurementState, PrepState.missing);
      expect(prepOf().measurementAgeDays, isNull);
    });

    test('a temperature is not a measurement', () {
      // Otherwise a fever last night would answer «когда взвешивали».
      final prep = prepOf(
        logs: [sickDay(ago: const Duration(days: 1), temperature: 38.2)],
      );

      expect(prep.lastMeasurement, isNull);
    });
  });

  group('the doses', () {
    test('are the overdue ones and the ones due in a fortnight, earliest '
        'first', () {
      final prep = prepOf(
        reminders: [
          dose('Корь, краснуха, паротит (ККП) — первая доза',
              until: const Duration(days: 5)),
          dose('Пневмококковая инфекция (ПНВ) — вторая доза',
              until: const Duration(days: -9)),
          dose('Гепатит A (ВГА) — первая доза',
              until: const Duration(days: 200)),
        ],
      );

      expect(prep.vaccines, hasLength(2));
      expect(prep.nextVaccine!.title, startsWith('Пневмококковая'));
      expect(prep.hasOverdueVaccine, isTrue);
      expect(prep.vaccineState, PrepState.attention);
    });

    test('a dose already given is not brought up again', () {
      final prep = prepOf(
        reminders: [
          dose('Полиомиелит (ОПВ)', until: const Duration(days: -3),
              done: true),
        ],
      );

      expect(prep.vaccines, isEmpty);
      expect(prep.vaccineState, PrepState.ready);
      expect(prep.nextVaccine, isNull);
    });
  });

  group('the food', () {
    test('separates what is new, what is still watched and what reacted', () {
      final prep = prepOf(
        logs: [
          spoon('Кабачок', ago: const Duration(days: 1)),
          spoon('Гречка', ago: const Duration(days: 20)),
          reaction('Гречка', 'сыпь на щеках',
              ago: const Duration(days: 19)),
        ],
        records: [visit(ago: const Duration(days: 10))],
      );

      expect(prep.newFoods.map((f) => f.name), ['Кабачок']);
      expect(prep.watchedFoods.map((f) => f.name), ['Кабачок']);
      // Outside the period, and still the answer to «на что была реакция».
      expect(prep.reactedFoods.map((f) => f.name), ['Гречка']);
      expect(prep.solidsState, PrepState.attention);
    });

    test('a food given long ago with nothing after it is quiet', () {
      final prep = prepOf(
        logs: [spoon('Гречка', ago: const Duration(days: 30))],
      );

      expect(prep.watchedFoods, isEmpty);
      expect(prep.reactedFoods, isEmpty);
      expect(prep.solidsState, PrepState.ready);
    });

    test('a child not on solids yet has no row at all', () {
      expect(prepOf().hasSolids, isFalse);
      expect(prepOf().solidsState, PrepState.missing);
    });
  });

  group('the report', () {
    List<DevelopmentLog> aWeek() => [
      question('Нормально ли, что срыгивает', ago: const Duration(days: 3)),
      spoon('Кабачок', ago: const Duration(days: 2)),
      spoon('Кабачок', ago: const Duration(days: 1)),
      spoon('Гречка', ago: const Duration(days: 40)),
      reaction('Гречка', 'сыпь на щеках', ago: const Duration(days: 39)),
    ];

    test('carries the questions and the foods, period or no period', () {
      // Both lists are deliberately outside the window: an unasked question
      // and an allergen do not expire because a week went by.
      final report = buildPeriodReport(
        child,
        aWeek(),
        ReportPeriod.week,
        now: now,
      );

      expect(report.questions.map((q) => q.text),
          ['Нормально ли, что срыгивает']);
      expect(report.foods.map((f) => f.name), ['Кабачок', 'Гречка']);
      expect(report.foods.first.times, 2);
      expect(report.foods.last.reactions.single.description, 'сыпь на щеках');
    });

    test('a week with nothing but a question is still worth printing', () {
      final report = buildPeriodReport(
        child,
        [question('Про сон', ago: const Duration(days: 1))],
        ReportPeriod.week,
        now: now,
      );

      expect(report.isEmpty, isFalse);
      expect(report.hasQuestions, isTrue);
      expect(report.hasFoods, isFalse);
    });

    test('and a week with nothing at all is still refused', () {
      final report = buildPeriodReport(
        child,
        const <DevelopmentLog>[],
        ReportPeriod.week,
        now: now,
      );

      expect(report.isEmpty, isTrue);
    });

    for (final locale in supportedLocales) {
      testWidgets('${locale.languageCode} prints both new sections', (
        tester,
      ) async {
        final l = await AppLocalizations.delegate.load(locale);
        final report = buildPeriodReport(
          child,
          aWeek(),
          ReportPeriod.week,
          now: now,
        );

        final bytes = await renderPeriodReport(
          report,
          l,
          localeName: locale.languageCode,
        );

        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
        expect(bytes.length, greaterThan(2000));
      });
    }

    test('every new label exists in all three languages', () async {
      for (final locale in supportedLocales) {
        final l = await AppLocalizations.delegate.load(locale);

        for (final label in [
          l.reportFoodName,
          l.reportFoodFirst,
          l.reportFoodTimes,
          l.reportFoodReaction,
          l.reportSectionQuestions,
          l.reportQuestion,
          l.reportAnswer,
          l.visitTitle,
          l.visitCardHint,
          l.visitOpen,
          l.visitMeasureTitle,
          l.visitMeasureNone,
          l.visitVaccinesTitle,
          l.visitVaccinesNone,
          l.visitHistoryTitle,
          l.visitHistoryEmpty,
          l.visitTakeTitle,
          l.visitTakeHint,
          l.navVisit,
          l.navVisitHint,
          l.visitQuestionsWaiting(2),
          l.visitMeasuredAt('01.08.2026', 8),
          l.visitVaccineDue('x', '01.08.2026'),
          l.visitVaccineOverdue('x', '01.08.2026'),
          l.visitFoodsNew(1),
          l.visitSinceVisit('01.08.2026'),
          l.visitSinceDays(30),
          l.visitSickDays(2),
          l.visitMaxTemperature('38.4'),
          l.visitMedicines(1),
        ]) {
          expect(label.trim(), isNotEmpty, reason: locale.languageCode);
        }
      }
    });

    test('none of the new wording interprets, advises or compares', () async {
      // The same rule the rest of the document lives by: it states what was
      // recorded, and a doctor is the one who decides what it means.
      const forbidden = [
        'норм', 'мало', 'много', 'рекоменд', 'следует', 'опасн', 'срочно',
        'normal', 'recommend', 'should', 'too few', 'too many', 'urgent',
      ];

      for (final locale in supportedLocales) {
        final l = await AppLocalizations.delegate.load(locale);
        final copy = [
          l.reportFoodName,
          l.reportFoodFirst,
          l.reportFoodTimes,
          l.reportFoodReaction,
          l.reportSectionQuestions,
          l.reportQuestion,
          l.reportAnswer,
          l.visitTitle,
          l.visitMeasureTitle,
          l.visitVaccinesTitle,
          l.visitHistoryTitle,
          l.visitTakeTitle,
          l.visitTakeHint,
        ].join(' ').toLowerCase();

        for (final word in forbidden) {
          expect(copy.contains(word), isFalse,
              reason: '«$word» in ${locale.languageCode}');
        }
      }
    });
  });

  group('the screen', () {
    Future<void> pump(
      WidgetTester tester, {
      List<DevelopmentLog> logs = const [],
      List<Reminder> reminders = const [],
    }) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            childrenProvider.overrideWith((ref) => Stream.value([child])),
            logsProvider.overrideWith((ref) => Stream.value(logs)),
            remindersProvider.overrideWith((ref) => Stream.value(reminders)),
          ],
          child: const ChildHealthApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('is reached from the medical card as well as the menu', (
      tester,
    ) async {
      await pump(tester);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      await tester.tap(find.text(l.navMedical).last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, l.visitOpen));
      await tester.pumpAndSettle();

      expect(find.text(l.visitMeasureTitle), findsOneWidget);
      expect(find.text(l.visitVaccinesTitle), findsOneWidget);
    });

    testWidgets('says what is ready and what is not', (tester) async {
      // Dated from the machine's own clock, not from the fixture's. The screen
      // asks what day it is, so a log pinned to a fixed date drifts by one
      // every midnight — this file's own fixture is at noon on 10 August and
      // the assertion below broke the first time the date rolled over.
      final realNow = DateTime.now();
      final measuredAt = realNow.subtract(const Duration(days: 40));

      await pump(
        tester,
        logs: [
          DevelopmentLog(
            id: 'm40',
            childId: 'c1',
            date: measuredAt,
            type: LogType.measurement,
            title: 'x',
            metrics: const Metrics(weightKg: 8.4, heightCm: 70),
          ),
          sickDay(ago: const Duration(days: 4), temperature: 38.4),
          medicine('Парацетамол', ago: const Duration(days: 4)),
        ],
        reminders: [
          dose('Полиомиелит (ОПВ)', until: const Duration(days: 4)),
        ],
      );
      final l = await AppLocalizations.delegate.load(defaultLocale);

      await tester.tap(find.text(l.navVisit).last);
      await tester.pumpAndSettle();

      // A month unweighed is flagged, and the line states both the date and
      // the gap — built here the same way the screen builds it.
      expect(
        find.text(l.visitMeasuredAt(shortDate.format(measuredAt), 40)),
        findsOneWidget,
      );
      expect(find.text(l.visitSickDays(1)), findsOneWidget);
      expect(find.text(l.visitMaxTemperature('38.4')), findsOneWidget);
      expect(find.text(l.visitMedicines(1)), findsOneWidget);
      expect(find.text(l.reportExport), findsOneWidget);
    });

    testWidgets('a question written here is on the list a moment later', (
      tester,
    ) async {
      // On the live demo store rather than a frozen stream: what is being
      // tested is that the question comes back out of the repository it was
      // written to.
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const ProviderScope(child: ChildHealthApp()),
      );
      await tester.pumpAndSettle();

      final l = await AppLocalizations.delegate.load(defaultLocale);

      await tester.tap(find.text(l.navVisit).last);
      await tester.pumpAndSettle();

      expect(find.text(l.medicalQuestionsHint), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, l.medicalWriteDown));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'Нормально ли, что срыгивает',
      );
      await tester.tap(find.widgetWithText(FilledButton, l.commonSave));
      await tester.pumpAndSettle();

      expect(find.text('Нормально ли, что срыгивает'), findsOneWidget);
    });

    testWidgets('an empty week says so instead of showing zeroes', (
      tester,
    ) async {
      await pump(tester);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      await tester.tap(find.text(l.navVisit).last);
      await tester.pumpAndSettle();

      expect(find.text(l.visitHistoryEmpty), findsOneWidget);
      expect(find.text(l.visitMeasureNone), findsOneWidget);
      expect(find.text(l.visitVaccinesNone), findsOneWidget);
    });
  });
}
