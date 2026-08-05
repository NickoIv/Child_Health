import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/features/shared/photo_widgets.dart';
import 'package:child_health_tracker/features/shared/widgets.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/models/photo.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// The diary read as a day rather than as a list: a rail down the left, the
/// clock down the right, and one line of substance in between.
void main() {
  setUpAll(initializeDateFormatting);

  const pixel =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

  final today = DateTime.now();

  DevelopmentLog log(
    LogType type, {
    required String title,
    Duration ago = const Duration(hours: 2),
    int? minutes,
    int? wakings,
    FeedingSide? side,
    NappyKind? nappy,
    double? temperature,
    List<String> photos = const [],
  }) => DevelopmentLog(
    id: title,
    childId: 'demo',
    date: today.subtract(ago),
    type: type,
    title: title,
    durationMinutes: minutes,
    nightWakings: wakings,
    feedingSide: side,
    nappyKind: nappy,
    photos: photos,
    metrics: Metrics(temperatureC: temperature),
  );

  /// One of each kind the timeline has to speak for.
  final entries = <DevelopmentLog>[
    log(LogType.feeding, title: 'Кормление', side: FeedingSide.left,
        ago: const Duration(minutes: 30)),
    log(LogType.nappy, title: 'Подгузник', nappy: NappyKind.wet,
        ago: const Duration(hours: 1)),
    log(LogType.sleep, title: 'Сон', minutes: 90,
        ago: const Duration(hours: 3)),
    log(LogType.sleep, title: 'Ночной сон', minutes: 540, wakings: 2,
        ago: const Duration(hours: 10)),
    log(LogType.illness, title: 'Температура', temperature: 38.4,
        ago: const Duration(hours: 5)),
    log(LogType.note, title: LogTitles.medicine,
        ago: const Duration(hours: 6)),
    log(LogType.note, title: 'Заметка', ago: const Duration(hours: 7)),
  ];

  Future<void> openDiary(
    WidgetTester tester, {
    List<DevelopmentLog>? logs,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          logsProvider.overrideWith((ref) => Stream.value(logs ?? entries)),
          photoProvider.overrideWith(
            (ref, id) async => Photo(
              id: id,
              childId: 'demo',
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

    await tester.tap(find.byIcon(Icons.auto_stories_outlined).first);
    await tester.pumpAndSettle();
  }

  testWidgets('every kind of entry gets a circle on the rail', (tester) async {
    await openDiary(tester);

    // Seven entries, seven markers — a feed and a night are not the same
    // event, and the icon is what says so at a glance.
    for (final icon in const [
      Icons.water_drop_outlined,
      Icons.child_care_outlined,
      Icons.bedtime_outlined,
      Icons.nightlight_outlined,
      Icons.thermostat,
      Icons.medication_outlined,
      Icons.notes,
    ]) {
      expect(find.byIcon(icon), findsWidgets, reason: '$icon is missing');
    }
  });

  testWidgets('the clock and how long ago sit on the right', (tester) async {
    await openDiary(tester);
    final l = await AppLocalizations.delegate.load(defaultLocale);

    // The exact time of the newest entry, and the same fact told the way a
    // tired parent actually thinks about it.
    expect(find.text(timeOfDayFor(entries.first.date)), findsWidgets);
    expect(find.textContaining(l.nowAgo('').trim()), findsWidgets);
  });

  testWidgets('an entry says what it was, not just its type', (tester) async {
    await openDiary(tester);
    final l = await AppLocalizations.delegate.load(defaultLocale);

    // Which side, how long, how hot — the summary line carries the substance.
    expect(find.textContaining(l.feedingLeft), findsWidgets);
    expect(find.textContaining(l.nappyWet), findsWidgets);
    expect(find.textContaining('38.4'), findsWidgets);
  });

  testWidgets('tapping a row opens it for editing, with no long press', (
    tester,
  ) async {
    await openDiary(tester);
    final l = await AppLocalizations.delegate.load(defaultLocale);

    await tester.tap(find.byType(IntrinsicHeight).first);
    await tester.pumpAndSettle();

    expect(find.text(l.diaryEditEntry), findsOneWidget);
  });

  group('photos', () {
    testWidgets('a single photo is one 64px thumbnail', (tester) async {
      await openDiary(tester, logs: [
        log(LogType.note, title: 'Заметка', photos: const ['a']),
      ]);

      final thumb = tester.widget<PhotoThumb>(find.byType(PhotoThumb));
      expect(thumb.size, 64);
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('several photos become one thumbnail and a count', (
      tester,
    ) async {
      await openDiary(tester, logs: [
        log(LogType.note, title: 'Заметка', photos: const ['a', 'b', 'c']),
      ]);

      // One preview, not a strip that pushes the next event off the screen.
      expect(find.byType(PhotoThumb), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('the count opens the viewer at the second photo', (
      tester,
    ) async {
      await openDiary(tester, logs: [
        log(LogType.note, title: 'Заметка', photos: const ['a', 'b', 'c']),
      ]);

      await tester.tap(find.text('+2'));
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('2 / 3'), findsOneWidget);
    });
  });

  testWidgets('on a desktop window the timeline stays a column', (
    tester,
  ) async {
    await openDiary(tester, size: const Size(1600, 1000));

    // Centred and capped: past this the rail and the clock drift so far
    // apart that the line between them stops reading as one event.
    final width = tester.getSize(find.byType(IntrinsicHeight).first).width;
    expect(width, lessThanOrEqualTo(760));

    // Centred within the area the shell leaves it, not within the window —
    // the navigation rail takes its share off the left.
    final body = tester.getRect(find.byType(PageBody));
    final row = tester.getRect(find.byType(IntrinsicHeight).first);
    expect(row.center.dx, closeTo(body.center.dx, 1));
  });

  testWidgets('on a phone it uses the full width', (tester) async {
    await openDiary(tester);

    final width = tester.getSize(find.byType(IntrinsicHeight).first).width;
    expect(width, greaterThan(280));
  });
}

/// The formatter the screen uses, applied to the same instant.
String timeOfDayFor(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:'
    '${date.minute.toString().padLeft(2, '0')}';
