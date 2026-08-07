import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/core/analytics/weekly_story.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/data/family_repository.dart';
import 'package:child_health_tracker/features/family/weekly_story_card.dart';
import 'package:child_health_tracker/features/reports/weekly_story_pdf.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/models/photo.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// The week both parents keep.
///
/// The arithmetic is the easy half. The half worth testing is what the card
/// refuses to be: no norm, no average, no comparison, nothing stored, and
/// nothing at all on screen in a week where nobody wrote anything down.
void main() {
  setUpAll(initializeDateFormatting);

  const pixel =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

  const fatherEmail = 'dad@example.com';
  final now = DateTime(2026, 8, 5, 20);

  final child = Child(
    id: 'c1',
    parentUid: 'mother-uid',
    name: 'Aisha',
    birthDate: DateTime(2025, 8, 2),
    gender: Gender.female,
  );

  DevelopmentLog log(
    LogType type, {
    required Duration ago,
    int? minutes,
    int? wakings,
    NappyKind? nappy,
    List<String> photos = const [],
    DateTime? from,
  }) => DevelopmentLog(
    id: '$type${ago.inMinutes}$minutes$wakings${photos.join()}',
    childId: child.id,
    date: (from ?? now).subtract(ago),
    type: type,
    title: 'x',
    durationMinutes: minutes,
    nightWakings: wakings,
    nappyKind: nappy,
    photos: photos,
  );

  List<DevelopmentLog> aWeek({DateTime? from}) => [
    for (var d = 0; d < 7; d++) ...[
      log(LogType.feeding, ago: Duration(days: d, hours: 2), from: from),
      log(LogType.feeding, ago: Duration(days: d, hours: 6), from: from),
      log(
        LogType.nappy,
        ago: Duration(days: d, hours: 3),
        nappy: NappyKind.wet,
        from: from,
      ),
      log(
        LogType.sleep,
        ago: Duration(days: d, hours: 12),
        minutes: 400 + d * 10,
        wakings: 2,
        from: from,
      ),
    ],
  ];

  group('the week', () {
    test('adds up feeds, sleep and nappies over seven days', () {
      final story = buildWeeklyStory(aWeek(), now);

      expect(story.feedings, 14);
      // Every stretch of sleep, nights included.
      expect(story.sleepMinutes, 400 + 410 + 420 + 430 + 440 + 450 + 460);
      expect(story.nappies, 7);
    });

    test('keeps the best night, not the average one', () {
      // An average night is arithmetic. The night everybody finally slept is
      // the one worth putting on a card.
      final story = buildWeeklyStory(aWeek(), now);
      expect(story.bestNightMinutes, 460);
    });

    test('a nap is not a night, however long it ran', () {
      final logs = [
        log(LogType.sleep, ago: const Duration(hours: 4), minutes: 200),
        log(
          LogType.sleep,
          ago: const Duration(hours: 20),
          minutes: 120,
          wakings: 1,
        ),
      ];
      final story = buildWeeklyStory(logs, now);

      expect(story.sleepMinutes, 320);
      // Only the entry that recorded wake-ups is a night.
      expect(story.bestNightMinutes, 120);
    });

    test('a week with no night recorded shows no best night', () {
      final logs = [log(LogType.sleep, ago: const Duration(hours: 4),
          minutes: 90)];
      expect(buildWeeklyStory(logs, now).hasBestNight, isFalse);
    });

    test('the eighth day back is not in it', () {
      final logs = [
        log(LogType.feeding, ago: const Duration(hours: 1)),
        log(LogType.feeding, ago: const Duration(days: 8)),
        log(LogType.nappy, ago: const Duration(days: 9), nappy: NappyKind.wet),
      ];
      final story = buildWeeklyStory(logs, now);

      expect(story.feedings, 1);
      expect(story.nappies, 0);
    });

    test('is computed from entries that already exist', () {
      // No story document, no weekly job, nothing to backfill: last week's
      // entries produce last week's story if you ask on last week's date.
      final logs = aWeek();
      expect(
        buildWeeklyStory(logs, now.subtract(const Duration(days: 14))).isEmpty,
        isTrue,
      );
      expect(buildWeeklyStory(logs, now).isEmpty, isFalse);
    });

    test('an empty week is empty, and says nothing about it', () {
      expect(buildWeeklyStory(const [], now).isEmpty, isTrue);
      expect(buildWeeklyStory(const [], now).hasCover, isFalse);
    });
  });

  group('the cover', () {
    test('is the newest photograph of the week', () {
      final logs = [
        log(LogType.note, ago: const Duration(days: 4), photos: const ['old']),
        log(LogType.note, ago: const Duration(hours: 5), photos: const ['new']),
        log(LogType.note, ago: const Duration(days: 2), photos: const ['mid']),
      ];
      expect(buildWeeklyStory(logs, now).coverPhotoId, 'new');
    });

    test('is not last month\'s photograph', () {
      final logs = [
        log(LogType.note, ago: const Duration(days: 20), photos: const ['old']),
      ];
      expect(buildWeeklyStory(logs, now).coverPhotoId, isNull);
    });

    test('a week of photographs and nothing else is still a week', () {
      // Pictures alone are enough to have had a week worth showing.
      final logs = [
        log(LogType.note, ago: const Duration(hours: 2), photos: const ['a']),
      ];
      expect(buildWeeklyStory(logs, now).isEmpty, isFalse);
    });
  });

  group('the warm title', () {
    test('is the same all week and the same on both phones', () {
      final monday = DateTime(2026, 8, 3, 7);
      for (var d = 0; d < 7; d++) {
        expect(
          titleForWeek(monday.add(Duration(days: d, hours: 5))),
          titleForWeek(monday),
          reason: 'day $d',
        );
      }
    });

    test('is a different one next week, and all three come round', () {
      final start = DateTime(2026, 8, 3);
      final titles = [
        for (var w = 0; w < 3; w++)
          titleForWeek(start.add(Duration(days: w * 7))),
      ];
      expect(titles.toSet(), hasLength(3));
    });

    test('the three exist in all three languages', () async {
      for (final locale in supportedLocales) {
        final l = await AppLocalizations.delegate.load(locale);
        final titles = StoryTitle.values.map((t) => storyTitle(l, t)).toList();

        expect(titles.toSet().length, 3, reason: locale.languageCode);
        for (final t in titles) {
          expect(t.trim(), isNotEmpty, reason: locale.languageCode);
        }
      }
    });

    test('the English wording is the wording asked for', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      expect(storyTitle(en, StoryTitle.care), 'A week of care');
      expect(storyTitle(en, StoryTitle.growing), 'Growing together');
      expect(storyTitle(en, StoryTitle.moments), 'Little moments, big love');
    });

    test('nothing in the wording grades anybody', () async {
      // A keepsake that quietly assesses the family is not a keepsake.
      const forbidden = [
        'норм', 'средн', 'должн', 'мало', 'больше чем', 'меньше',
        'normal', 'average', 'should', 'less than', 'more than', 'percentile',
      ];

      for (final locale in supportedLocales) {
        final l = await AppLocalizations.delegate.load(locale);
        final copy = [
          for (final t in StoryTitle.values) storyTitle(l, t),
          l.storyFeedings,
          l.storySleep,
          l.storyNappies,
          l.storyBestNight,
        ].join(' ').toLowerCase();

        for (final word in forbidden) {
          expect(copy.contains(word), isFalse,
              reason: '«$word» in ${locale.languageCode}');
        }
      }
    });
  });

  group('the filename', () {
    test('survives a name with spaces and slashes in it', () {
      expect(storyFilename('Aisha'), 'week_Aisha.pdf');
      expect(storyFilename(' Ай ша '), 'week_Ай_ша.pdf');
      expect(storyFilename('a/b'), 'week_a_b.pdf');
      expect(storyFilename('   '), 'week.pdf');
    });
  });

  group('on the screen', () {
    Future<void> pump(
      WidgetTester tester, {
      required FamilyRepository family,
      required String email,
      List<DevelopmentLog> logs = const [],
    }) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            familyRepositoryProvider.overrideWithValue(family),
            currentEmailProvider.overrideWithValue(email),
            childrenProvider.overrideWith((ref) => Stream.value([child])),
            logsProvider.overrideWith((ref) => Stream.value(logs)),
            photoProvider.overrideWith(
              (ref, id) async => Photo(
                id: id,
                childId: child.id,
                base64Data: pixel,
                width: 1,
                height: 1,
                createdAt: DateTime(2026),
              ),
            ),
          ],
          child: const ChildHealthApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<MemoryFamilyRepository> familyWithViewer() async {
      final family = MemoryFamilyRepository();
      final invitation = await family.invite(
        childId: child.id,
        ownerUid: child.parentUid,
        email: fatherEmail,
      );
      await family.accept(invitation, 'demo-uid');
      return family;
    }

    /// The week lives on the assistant tab now — see [DashboardScreen], which
    /// keeps the home screen to the four things a parent opens it to do.
    /// The same week, anchored to the calendar rather than to the clock.
    ///
    /// `aWeek(from: DateTime.now())` puts the oldest entries six and a half
    /// days back, which falls outside the window when the suite runs just
    /// after midnight. This keeps every entry inside the day it belongs to.
    List<DevelopmentLog> aWeekOnScreen() {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final elapsed = now.difference(midnight).inMinutes;
      DateTime at(int daysBack, int slot) => midnight
          .subtract(Duration(days: daysBack))
          .add(Duration(minutes: elapsed * (slot + 1) ~/ 5));

      return [
        for (var d = 0; d < 7; d++) ...[
          DevelopmentLog(
            id: 'f1-$d',
            childId: child.id,
            date: at(d, 0),
            type: LogType.feeding,
            title: 'x',
          ),
          DevelopmentLog(
            id: 'f2-$d',
            childId: child.id,
            date: at(d, 1),
            type: LogType.feeding,
            title: 'x',
          ),
          DevelopmentLog(
            id: 'n-$d',
            childId: child.id,
            date: at(d, 2),
            type: LogType.nappy,
            title: 'x',
            nappyKind: NappyKind.wet,
          ),
          DevelopmentLog(
            id: 's-$d',
            childId: child.id,
            date: at(d, 3),
            type: LogType.sleep,
            title: 'x',
            durationMinutes: 400 + d * 10,
            nightWakings: 2,
          ),
        ],
      ];
    }

    Future<void> scrollToStory(WidgetTester tester) async {
      final l = await AppLocalizations.delegate.load(defaultLocale);
      await tester.tap(find.text(l.navAssistant).last);
      await tester.pumpAndSettle();
      // The tab is two halves now; everything that is read rather than looked
      // up lives behind «Сводка».
      await tester.tap(find.text(l.assistantViewInsights));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(WeeklyStoryCard),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the mother gets the week, its title and its numbers', (
      tester,
    ) async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);

      await pump(
        tester,
        family: family,
        email: 'demo@example.com',
        logs: aWeekOnScreen(),
      );
      final l = await AppLocalizations.delegate.load(defaultLocale);
      await scrollToStory(tester);

      expect(
        find.text(storyTitle(l, titleForWeek(DateTime.now()))),
        findsOneWidget,
      );
      expect(find.text(l.storyFeedings), findsOneWidget);
      expect(find.text(l.storySleep), findsOneWidget);
      expect(find.text(l.storyNappies), findsOneWidget);
      expect(find.text(l.storyBestNight), findsOneWidget);
      expect(find.text('14'), findsWidgets);
    });

    testWidgets('the father gets exactly the same card', (tester) async {
      final family = await familyWithViewer();
      addTearDown(family.dispose);

      await pump(
        tester,
        family: family,
        email: fatherEmail,
        logs: aWeekOnScreen(),
      );
      final l = await AppLocalizations.delegate.load(defaultLocale);
      await scrollToStory(tester);

      // Both parents, unlike the digest: the week is a keepsake, not a
      // briefing for whoever was out of the room. Scoped to the card, since
      // the digest above it on this tab counts feeds under the same word.
      expect(
        find.descendant(
          of: find.byType(WeeklyStoryCard),
          matching: find.text(l.storyFeedings),
        ),
        findsOneWidget,
      );
      // And he can send it — exporting reads the record and writes nothing.
      expect(find.text(l.storyExport), findsOneWidget);
    });

    testWidgets('a week with nothing in it draws nothing', (tester) async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);

      await pump(tester, family: family, email: 'demo@example.com');
      final l = await AppLocalizations.delegate.load(defaultLocale);
      await tester.tap(find.text(l.navAssistant).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.assistantViewInsights));
      await tester.pumpAndSettle();

      expect(find.text(l.storyFeedings), findsNothing);
      expect(find.text(l.storyExport), findsNothing);
      final card = find.byType(WeeklyStoryCard);
      expect(card.evaluate().isEmpty ? 0.0 : tester.getSize(card).height, 0);
    });

    testWidgets('the cover opens the viewer the diary already uses', (
      tester,
    ) async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);

      await pump(
        tester,
        family: family,
        email: 'demo@example.com',
        logs: [
          ...aWeekOnScreen(),
          DevelopmentLog(
            id: 'cover',
            childId: child.id,
            date: DateTime.now().subtract(const Duration(minutes: 30)),
            type: LogType.note,
            title: 'x',
            photos: const ['cover-photo'],
          ),
        ],
      );
      final l = await AppLocalizations.delegate.load(defaultLocale);
      await scrollToStory(tester);

      await tester.tap(
        find.descendant(
          of: find.byType(WeeklyStoryCard),
          matching: find.byType(Image),
        ).first,
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip(l.commonClose), findsOneWidget);
    });

    testWidgets('nothing on the card compares the week with anything', (
      tester,
    ) async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);

      await pump(
        tester,
        family: family,
        email: 'demo@example.com',
        logs: aWeekOnScreen(),
      );
      final l = await AppLocalizations.delegate.load(defaultLocale);
      await scrollToStory(tester);

      // No percentile, no norm, no verdict — and nothing borrowed from the
      // screens that legitimately have them.
      for (final absent in [
        l.growthVerdictNormal,
        l.growthVerdictLow,
        l.growthVerdictHigh,
        l.growthPercentileWord,
      ]) {
        expect(
          find.descendant(
            of: find.byType(WeeklyStoryCard),
            matching: find.text(absent),
          ),
          findsNothing,
        );
      }
    });
  });
}
