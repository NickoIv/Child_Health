import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/core/care/solids.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/features/medical/solids_card.dart';
import 'package:child_health_tracker/features/reports/period_report.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// First foods, and what followed them.
///
/// The feature is one table a doctor asks for out loud, so what is tested is
/// that the table is right: that it is built from the feeds she was already
/// making, that two spellings of a courgette are one courgette, that a new
/// food is watched for three days, and that a spoon is never counted as a
/// breast in the report a doctor reads.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeDateFormatting);

  final now = DateTime(2026, 8, 9, 12);

  DevelopmentLog spoon(String food, DateTime at) => DevelopmentLog(
    id: '$food$at',
    childId: 'c1',
    date: at,
    type: LogType.feeding,
    title: LogType.feeding.label,
    feedingSide: FeedingSide.solid,
    food: food,
  );

  DevelopmentLog reaction(String food, DateTime at, String what) =>
      DevelopmentLog(
        id: 'r$food$at',
        childId: 'c1',
        date: at,
        type: LogType.note,
        title: LogTitles.reaction,
        description: what,
        food: food,
      );

  group('a spoon', () {
    test('is a feed with a name, not a type of its own', () {
      final log = spoon('Кабачок', now);
      expect(log.type, LogType.feeding);
      expect(log.isSolid, isTrue);
      expect(FeedingSide.solid.isMilk, isFalse);
      expect(FeedingSide.bottle.isMilk, isTrue);
    });

    test('survives the trip to storage and back', () {
      final map = spoon('Кабачок', now).toMap();
      expect(map['feeding_side'], 'solid');
      expect(map['food'], 'Кабачок');

      final read = DevelopmentLog.fromMap('x', map);
      expect(read.feedingSide, FeedingSide.solid);
      expect(read.food, 'Кабачок');
      expect(read.isSolid, isTrue);
    });

    test('is shown to an older build as a feed rather than as a crash', () {
      // What a client that predates `solid` does with the code it has never
      // seen: the same thing it already did with a missing field.
      expect(FeedingSide.fromCode('sausage'), isNull);
    });

    test('names itself on the timeline', () {
      expect(spoon('Кабачок', now).routineSummary, contains('Кабачок'));
      expect(spoon('Кабачок', now).routineSummary, contains('Прикорм'));
    });
  });

  group('the table', () {
    test('groups two spellings of one food', () {
      final foods = foodsIn([
        spoon('кабачок ', now),
        spoon('Кабачок', now.subtract(const Duration(days: 1))),
        spoon('КАБАЧОК', now.subtract(const Duration(days: 2))),
      ]);

      expect(foods, hasLength(1));
      expect(foods.single.times, 3);
      // Shown back to her as she first wrote it, whatever the grouping did.
      expect(foods.single.name, 'кабачок');
      expect(foods.single.firstAt, now.subtract(const Duration(days: 2)));
      expect(foods.single.lastAt, now);
    });

    test('puts the newest introduction first, because that is the question', () {
      final foods = foodsIn([
        spoon('Груша', now),
        spoon('Кабачок', now.subtract(const Duration(days: 10))),
      ]);
      expect(foods.map((f) => f.name), ['Груша', 'Кабачок']);
    });

    test('carries every reaction, newest first, in her own words', () {
      final foods = foodsIn([
        reaction('Кабачок', now, 'Сыпь на щеках к вечеру'),
        reaction('Кабачок', now.subtract(const Duration(days: 1)), 'Красные щёки'),
        spoon('Кабачок', now.subtract(const Duration(days: 2))),
      ]);

      final record = foods.single;
      expect(record.hadReaction, isTrue);
      expect(record.reactions, hasLength(2));
      expect(record.reactions.first.description, 'Сыпь на щеках к вечеру');
    });

    test('keeps a reaction to a food that was never written down', () {
      // Somebody else's kitchen, or written up after the fact. It is the
      // reaction that matters, not the bookkeeping.
      final foods = foodsIn([reaction('Клубника', now, 'Сыпь')]);
      expect(foods.single.name, 'Клубника');
      expect(foods.single.times, 0);
      expect(foods.single.hadReaction, isTrue);
    });

    test('ignores an ordinary feed and an ordinary note', () {
      expect(
        foodsIn([
          DevelopmentLog(
            id: 'f',
            childId: 'c1',
            date: now,
            type: LogType.feeding,
            title: LogType.feeding.label,
            feedingSide: FeedingSide.left,
          ),
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

  group('the three days a new food is watched', () {
    test('start at the first spoon and end after three of them', () {
      final fresh = foodsIn([spoon('Груша', now)]).single;
      expect(fresh.isUnderWatchAt(now), isTrue);
      expect(fresh.isUnderWatchAt(now.add(const Duration(days: 2))), isTrue);
      expect(fresh.isUnderWatchAt(now.add(const Duration(days: 3))), isFalse);
      expect(fresh.watchUntil, now.add(const Duration(days: newFoodWatchDays)));
    });

    test('stop the moment there is something to report', () {
      final reacted = foodsIn([
        spoon('Груша', now),
        reaction('Груша', now.add(const Duration(hours: 5)), 'Сыпь'),
      ]).single;
      // Nothing is being waited for any more; what happened is on the card.
      expect(reacted.isUnderWatchAt(now.add(const Duration(hours: 6))), isFalse);
    });
  });

  group('the foods offered back as chips', () {
    test('are the ones she has used, newest first and each once', () {
      final names = recentFoods([
        spoon('Груша', now),
        spoon('Кабачок', now.subtract(const Duration(hours: 4))),
        spoon('груша', now.subtract(const Duration(days: 1))),
        spoon('Гречка', now.subtract(const Duration(days: 2))),
      ]);
      expect(names, ['Груша', 'Кабачок', 'Гречка']);
    });
  });

  group('the report a doctor reads', () {
    test('does not count a courgette as a breast', () {
      final child = Child(
        id: 'c1',
        parentUid: 'p1',
        name: 'Айша',
        birthDate: DateTime(2025, 8, 9),
        gender: Gender.female,
      );
      final report = buildPeriodReport(
        child,
        [
          spoon('Кабачок', now.subtract(const Duration(hours: 2))),
          DevelopmentLog(
            id: 'b',
            childId: 'c1',
            date: now.subtract(const Duration(hours: 3)),
            type: LogType.feeding,
            title: LogType.feeding.label,
            feedingSide: FeedingSide.left,
          ),
        ],
        ReportPeriod.week,
        now: now,
      );

      expect(report.feedings, 2);
      expect(report.breastFeedings, 1);
      expect(report.bottleFeedings, 0);
    });
  });

  group('on the screens', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<void> pumpApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const ProviderScope(child: ChildHealthApp()));
      await tester.pumpAndSettle();
    }

    testWidgets('the spoon is the fourth way food arrives', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.widgetWithText(InkWell, 'Покормила'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сейчас'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Прикорм'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Прикорм'));
      await tester.pumpAndSettle();

      // A spoon has a name, so it asks for one — and says why the three days
      // matter while it is asking.
      expect(find.text('Что ели'), findsOneWidget);
      expect(find.textContaining('Три дня'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'Кабачок');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Записать'));
      await tester.pumpAndSettle();

      expect(find.text('Записано: прикорм, кабачок'), findsOneWidget);
    });

    testWidgets('the medical card lists it and takes a reaction', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final child = Child(
        id: 'c1',
        parentUid: 'p1',
        name: 'Айша',
        birthDate: DateTime(2025, 8, 9),
        gender: Gender.female,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            childrenProvider.overrideWith((ref) => Stream.value([child])),
            logsProvider.overrideWith(
              (ref) => Stream.value([
                spoon('Кабачок', DateTime.now()),
                spoon('Гречка', DateTime.now().subtract(
                  const Duration(days: 20),
                )),
              ]),
            ),
          ],
          child: MaterialApp(
            locale: defaultLocale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: SolidsCard(childId: 'c1')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Кабачок'), findsOneWidget);
      expect(find.text('Гречка'), findsOneWidget);
      // The new one is being watched; the one from three weeks ago is not.
      expect(find.textContaining('наблюдаем до'), findsOneWidget);

      await tester.tap(find.text('Была реакция').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Реакция на'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Сыпь на щеках');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Записать'));
      await tester.pumpAndSettle();

      expect(find.text('Записано: кабачок'), findsOneWidget);
    });
  });
}
