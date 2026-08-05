import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/core/analytics/daily_digest.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/data/family_repository.dart';
import 'package:child_health_tracker/features/family/digest_card.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// The day, condensed for the parent who was not there.
///
/// Two things are being checked: that the arithmetic comes from the logs and
/// nowhere else, and that the card never appears for the mother — for whom it
/// would be the app narrating her own afternoon back at her.
void main() {
  setUpAll(initializeDateFormatting);

  const fatherEmail = 'dad@example.com';
  final today = DateTime(2026, 8, 5, 20);

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
    double? temperature,
    List<String> photos = const [],
    String title = 'x',
  }) => DevelopmentLog(
    id: '$type$ago$minutes$temperature${photos.length}$wakings',
    childId: child.id,
    date: today.subtract(ago),
    type: type,
    title: title,
    durationMinutes: minutes,
    nightWakings: wakings,
    nappyKind: nappy,
    photos: photos,
    metrics: Metrics(temperatureC: temperature),
  );

  List<DevelopmentLog> anOrdinaryDay() => [
    for (var i = 0; i < 5; i++)
      log(LogType.feeding, ago: Duration(hours: i * 2 + 1)),
    log(LogType.nappy, ago: const Duration(hours: 2), nappy: NappyKind.wet),
    log(LogType.nappy, ago: const Duration(hours: 4), nappy: NappyKind.dirty),
    log(LogType.nappy, ago: const Duration(hours: 6), nappy: NappyKind.both),
    log(LogType.sleep, ago: const Duration(hours: 5), minutes: 90),
    log(LogType.sleep, ago: const Duration(hours: 9), minutes: 45),
    log(LogType.illness, ago: const Duration(hours: 3), temperature: 37.4),
    log(LogType.note, ago: const Duration(hours: 7), photos: const ['a', 'b']),
    log(LogType.milestone, ago: const Duration(hours: 8), photos: const ['c']),
  ];

  group('the arithmetic', () {
    test('counts the five things and nothing else', () {
      final d = buildDailyDigest(anOrdinaryDay(), today);

      expect(d.feedings, 5);
      expect(d.sleepMinutes, 135);
      // Both kinds counted, and "wet and dirty" counted on both sides — the
      // same way the daily care block already counts them.
      expect(d.nappies, 4);
      expect(d.lastTemperature, 37.4);
      expect(d.photos, 3);
    });

    test('the temperature is the latest one, not the highest', () {
      // A reading taken later is the one that answers "how is she now".
      // Picking the highest of the day would quietly turn the card into an
      // alarm about something already dealt with.
      final logs = [
        log(LogType.illness, ago: const Duration(hours: 8), temperature: 38.6),
        log(LogType.measurement, ago: const Duration(hours: 1),
            temperature: 36.9),
      ];
      expect(buildDailyDigest(logs, today).lastTemperature, 36.9);
    });

    test('no reading means no number, not a zero', () {
      final logs = [log(LogType.feeding, ago: const Duration(hours: 1))];
      expect(buildDailyDigest(logs, today).lastTemperature, isNull);
    });

    test('yesterday is not today', () {
      final logs = [
        log(LogType.feeding, ago: const Duration(hours: 1)),
        log(LogType.feeding, ago: const Duration(days: 1, hours: 1)),
        log(LogType.note, ago: const Duration(days: 1), photos: const ['old']),
      ];
      final d = buildDailyDigest(logs, today);

      expect(d.feedings, 1);
      expect(d.photos, 0);
    });

    test('an empty day says so rather than showing five zeroes', () {
      final d = buildDailyDigest(const [], today);

      expect(d.isEmpty, isTrue);
      expect(d.feedings, 0);
      expect(d.photos, 0);
      expect(d.lastTemperature, isNull);
    });

    test('is built from logs and photo ids that already exist', () {
      // The point of the feature: no digest document, no backfill, nothing to
      // keep in step. Yesterday's data produces yesterday's digest today.
      final logs = anOrdinaryDay();
      final yesterday = buildDailyDigest(logs, today.subtract(
        const Duration(days: 1),
      ));
      expect(yesterday.isEmpty, isTrue);
    });
  });

  group('the warm line', () {
    test('an ordinary day is a calm one', () {
      expect(buildDailyDigest(anOrdinaryDay(), today).mood, DayMood.calm);
    });

    test('a day with a great deal written down is a busy one', () {
      final logs = [
        for (var i = 0; i < DigestThresholds.busyEntries + 1; i++)
          log(LogType.feeding, ago: Duration(minutes: i * 10 + 5)),
      ];
      expect(buildDailyDigest(logs, today).mood, DayMood.busy);
    });

    test('a night nobody slept through outranks a busy day', () {
      // Telling someone the day was lovely after four wake-ups is the kind of
      // cheerfulness that reads as not paying attention.
      final logs = [
        for (var i = 0; i < DigestThresholds.busyEntries + 1; i++)
          log(LogType.feeding, ago: Duration(minutes: i * 10 + 5)),
        log(LogType.sleep, ago: const Duration(hours: 14), minutes: 400,
            wakings: DigestThresholds.hardNightWakings),
      ];
      expect(buildDailyDigest(logs, today).mood, DayMood.hardNight);
    });

    test('last night counts even though it was entered yesterday', () {
      // A night is one block dated to the evening it began, so the night this
      // morning is living with sits on yesterday's date.
      final logs = [
        log(LogType.feeding, ago: const Duration(hours: 2)),
        log(LogType.sleep, ago: const Duration(days: 1, hours: 2),
            minutes: 420, wakings: 5),
      ];
      expect(buildDailyDigest(logs, today).mood, DayMood.hardNight);
    });

    test('two wake-ups is an ordinary night', () {
      final logs = [
        log(LogType.sleep, ago: const Duration(hours: 14), minutes: 500,
            wakings: 2),
      ];
      expect(buildDailyDigest(logs, today).mood, DayMood.calm);
    });

    test('the three sentences exist in all three languages', () async {
      for (final locale in supportedLocales) {
        final l = await AppLocalizations.delegate.load(locale);
        final lines = DayMood.values.map((m) => warmLine(l, m)).toList();

        expect(lines.toSet().length, 3, reason: locale.languageCode);
        for (final line in lines) {
          expect(line.trim(), isNotEmpty, reason: locale.languageCode);
        }
      }
    });

    test('nothing in the wording judges anyone', () async {
      // The line describes the day. The moment it describes the mother, or
      // the child's health, it stops being warm and starts being a verdict
      // the app is in no position to hand down.
      const forbidden = [
        'норм', 'плохо', 'мало', 'должн', 'следует', 'тревож',
        'bad', 'poor', 'should', 'normal', 'worry', 'concern',
      ];

      for (final locale in supportedLocales) {
        final l = await AppLocalizations.delegate.load(locale);
        final copy =
            DayMood.values.map((m) => warmLine(l, m)).join(' ').toLowerCase();

        for (final word in forbidden) {
          expect(copy.contains(word), isFalse,
              reason: '«$word» in ${locale.languageCode}');
        }
      }
    });

    test('the English wording is the wording asked for', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      expect(warmLine(en, DayMood.calm), 'Today was a calm day.');
      expect(warmLine(en, DayMood.busy), 'Today was a busy day.');
      expect(
        warmLine(en, DayMood.hardNight),
        'The night was a little difficult.',
      );
    });
  });

  group('on the screen', () {
    Future<void> pump(
      WidgetTester tester, {
      required FamilyRepository family,
      required String email,
      List<DevelopmentLog> logs = const [],
    }) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            familyRepositoryProvider.overrideWithValue(family),
            currentEmailProvider.overrideWithValue(email),
            childrenProvider.overrideWith((ref) => Stream.value([child])),
            logsProvider.overrideWith((ref) => Stream.value(logs)),
          ],
          child: const ChildHealthApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// An accepted invitation, which is what makes a session a viewer's.
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

    testWidgets('the father gets the digest', (tester) async {
      final family = await familyWithViewer();
      addTearDown(family.dispose);

      // Dated to now so the digest, which asks about today, finds them.
      final now = DateTime.now();
      await pump(
        tester,
        family: family,
        email: fatherEmail,
        logs: [
          DevelopmentLog(
            id: 'f1',
            childId: child.id,
            date: now.subtract(const Duration(hours: 1)),
            type: LogType.feeding,
            title: 'Кормление',
          ),
          DevelopmentLog(
            id: 'n1',
            childId: child.id,
            date: now.subtract(const Duration(hours: 2)),
            type: LogType.nappy,
            title: 'Подгузник',
            nappyKind: NappyKind.wet,
          ),
          DevelopmentLog(
            id: 'p1',
            childId: child.id,
            date: now.subtract(const Duration(hours: 3)),
            type: LogType.note,
            title: 'Заметка',
            photos: const ['a', 'b'],
          ),
        ],
      );
      final l = await AppLocalizations.delegate.load(defaultLocale);

      expect(find.byType(DigestCard), findsOneWidget);
      // Scoped to the card: after six in the evening the reflection block is
      // on the same screen, and its heading is the same word.
      expect(
        find.descendant(
          of: find.byType(DigestCard),
          matching: find.text(l.digestTitle),
        ),
        findsOneWidget,
      );
      expect(find.text(l.digestFeedings), findsOneWidget);
      expect(find.text(l.digestNappies), findsOneWidget);
      expect(find.text(l.digestPhotos), findsOneWidget);
      // And the sentence, which is the whole reason it is not a table.
      expect(find.text(l.digestCalm), findsOneWidget);
    });

    testWidgets('the mother never sees it', (tester) async {
      final family = await familyWithViewer();
      addTearDown(family.dispose);

      await pump(tester, family: family, email: 'demo@example.com');
      final l = await AppLocalizations.delegate.load(defaultLocale);

      // She lived the day; summarising it back to her would be noise.
      expect(find.text(l.digestTitle), findsNothing);
      expect(find.text(l.digestCalm), findsNothing);
      expect(find.text(l.digestBusy), findsNothing);
    });

    testWidgets('a quiet morning says so instead of showing zeroes', (
      tester,
    ) async {
      final family = await familyWithViewer();
      addTearDown(family.dispose);

      await pump(tester, family: family, email: fatherEmail);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      expect(find.text(l.digestEmpty), findsOneWidget);
      expect(find.text(l.digestFeedings), findsNothing);
    });
  });
}
