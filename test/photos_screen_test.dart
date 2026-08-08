import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/data/memory_repository.dart';
import 'package:child_health_tracker/features/photos/photos_screen.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The carousel, on screen.
///
/// One picture at a time with the day and the words under it — a grid is for
/// finding a photograph you know exists, and this is for looking at them.
void main() {
  setUpAll(initializeDateFormatting);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // The app sets this from the chosen language as it builds; a bare
    // MaterialApp does not, and the dates come back in English without it.
    Intl.defaultLocale = 'ru';
  });

  final child = Child(
    id: 'demo',
    parentUid: 'parent',
    name: 'Маус',
    birthDate: DateTime(2026, 2, 1),
    gender: Gender.male,
  );

  DevelopmentLog log(
    String id, {
    required DateTime date,
    List<String> photos = const [],
    String description = '',
    String title = 'Прогулка',
  }) => DevelopmentLog(
    id: id,
    childId: child.id,
    date: date,
    type: LogType.note,
    title: title,
    description: description,
    photos: photos,
  );

  Future<MemoryDevelopmentLogRepository> pump(
    WidgetTester tester, {
    required List<DevelopmentLog> logs,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Seeded and then emptied: the only constructor builds the demo profile,
    // and this test is about the photographs it is given, not those.
    final db = MemoryDatabase.seeded('parent');
    addTearDown(db.dispose);
    db.logs.mutate((items) => items.clear());

    final repository = MemoryDevelopmentLogRepository(db);
    for (final entry in logs) {
      await repository.add(entry);
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          childrenProvider.overrideWith((ref) => Stream.value([child])),
          // Reading and writing are deliberately separate here. Pointing the
          // screen at the repository's own live stream makes a save re-emit
          // into the frame that is popping the sheet, and this harness spins
          // on that for ever. What the test is about is the write, so the
          // screen gets a fixed snapshot and the repository gets the edit.
          logsProvider.overrideWith((ref) => Stream.value(logs)),
          logRepositoryProvider.overrideWithValue(repository),
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
          home: const PhotosScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('an empty album says so rather than showing nothing', (
    tester,
  ) async {
    await pump(tester, logs: []);
    final l = await AppLocalizations.delegate.load(defaultLocale);

    expect(find.text(l.photosEmpty), findsOneWidget);
    // And the way to fill it is on the same screen.
    expect(
      find.widgetWithText(FloatingActionButton, l.photosAdd),
      findsOneWidget,
    );
  });

  testWidgets('it shows one picture with its day and its words', (
    tester,
  ) async {
    await pump(tester, logs: [
      log(
        'a',
        date: DateTime(2026, 8, 2, 15, 30),
        photos: ['p1'],
        description: 'первый раз сел сам',
      ),
    ]);

    expect(find.text('первый раз сел сам'), findsOneWidget);
    expect(find.textContaining('2 августа 2026'), findsOneWidget);
    expect(find.textContaining('15:30'), findsOneWidget);
  });

  testWidgets('a picture with no words is labelled by its entry', (
    tester,
  ) async {
    await pump(tester, logs: [
      log('a', date: DateTime(2026, 8, 2), photos: ['p1'], title: 'Прогулка'),
    ]);

    // «Прогулка» under a photograph says more than an empty line.
    expect(find.text('Прогулка'), findsOneWidget);
  });

  testWidgets('the count is the whole album, across entries', (tester) async {
    await pump(tester, logs: [
      log('a', date: DateTime(2026, 8, 1), photos: ['p1', 'p2']),
      log('b', date: DateTime(2026, 8, 2), photos: ['p3']),
    ]);
    final l = await AppLocalizations.delegate.load(defaultLocale);

    expect(find.text(l.photosCount(3)), findsOneWidget);
  });

  testWidgets('the newest is the one it opens on', (tester) async {
    await pump(tester, logs: [
      log('old', date: DateTime(2026, 7, 1), photos: ['p1'], description: 'июль'),
      log('new', date: DateTime(2026, 8, 6), photos: ['p2'], description: 'август'),
    ]);

    expect(find.text('август'), findsOneWidget);
    expect(find.text('июль'), findsNothing);
  });

  testWidgets('the pencil opens the sheet on that entry, ready to correct', (
    tester,
  ) async {
    await pump(tester, logs: [
      log('a', date: DateTime(2026, 8, 2), photos: ['p1'], description: 'до'),
    ]);
    final l = await AppLocalizations.delegate.load(defaultLocale);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    // In edit mode, holding what the entry already says — not an empty form
    // that would write a second record beside it.
    expect(find.text(l.photosEdit), findsOneWidget);
    expect(find.widgetWithText(TextField, 'до'), findsOneWidget);
    expect(find.text('02.08.2026'), findsOneWidget);

    // What that save writes is `editedPhotoLog`, held down in
    // photo_album_test.dart: driving it from here hangs this harness, and a
    // green test bought by guessing at the cause would be worth less than
    // saying so.
  });

  testWidgets('a photo on somebody else\'s entry cannot be deleted here', (
    tester,
  ) async {
    await pump(tester, logs: [
      log('a', date: DateTime(2026, 8, 2), photos: ['p1'], title: 'Кормление'),
    ]);
    final l = await AppLocalizations.delegate.load(defaultLocale);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    // Deleting a feed because you did not like the picture on it would be the
    // album deciding what the diary says.
    expect(find.widgetWithText(TextButton, l.commonDelete), findsNothing);
  });

  testWidgets('one made of the photograph can be', (tester) async {
    await pump(tester, logs: [
      log(
        'a',
        date: DateTime(2026, 8, 2),
        photos: ['p1'],
        title: LogTitles.photo,
      ),
    ]);
    final l = await AppLocalizations.delegate.load(defaultLocale);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextButton, l.commonDelete), findsOneWidget);
  });
}
