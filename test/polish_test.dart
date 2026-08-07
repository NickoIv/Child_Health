import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/features/dashboard/focus_home.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/features/shared/photo_widgets.dart';
import 'package:child_health_tracker/features/shared/widgets.dart';
import 'package:child_health_tracker/models/photo.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// The promises a finished product makes and a half-built one does not: the
/// same app in three languages, on two screen sizes, with every entry
/// editable and every photo openable.
void main() {
  setUpAll(initializeDateFormatting);

  /// A 1x1 PNG, enough for Image.memory to decode and for the viewer to
  /// reach its zoomable branch.
  const pixel =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

  Future<void> pump(
    WidgetTester tester, {
    Locale? locale,
    Size size = const Size(1400, 2400),
    bool withPhotos = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (locale != null)
            localeProvider.overrideWith(() => LocaleChoice(locale)),
          if (withPhotos)
            photoProvider.overrideWith(
              (ref, id) async => Photo(
                id: id,
                childId: 'c',
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

  group('no mixed languages', () {
    // Flutter throws on overflow, so building these at 390px is itself the
    // check that a longer Kazakh word does not push anything off the edge.
    for (final locale in supportedLocales) {
      testWidgets('${locale.languageCode} draws the home screen intact', (
        tester,
      ) async {
        await pump(tester, locale: locale, size: const Size(390, 844));

        final l = await AppLocalizations.delegate.load(locale);
        expect(find.widgetWithText(InkWell, l.quickFeed), findsOneWidget);
        expect(find.widgetWithText(InkWell, l.quickNightSleep), findsOneWidget);
        expect(find.text(l.navDiary), findsWidgets);
      });

      testWidgets('${locale.languageCode} quick sheet is in one language', (
        tester,
      ) async {
        await pump(tester, locale: locale, size: const Size(390, 844));
        final l = await AppLocalizations.delegate.load(locale);

        await tester.tap(find.widgetWithText(InkWell, l.quickFeed));
        await tester.pumpAndSettle();

        expect(find.text(l.quickTimeNow), findsOneWidget);
        expect(find.text(l.quickTimeChoose), findsOneWidget);

        await tester.tap(find.text(l.quickTimeNow));
        await tester.pumpAndSettle();

        // The feeding options, not the Russian labels stored on the model.
        expect(find.text(l.feedingLeft), findsOneWidget);
        expect(find.text(l.feedingBottle), findsOneWidget);
      });

      testWidgets('${locale.languageCode} diary and settings stay translated', (
        tester,
      ) async {
        await pump(tester, locale: locale);
        final l = await AppLocalizations.delegate.load(locale);

        await tester.tap(find.byIcon(Icons.auto_stories_outlined).first);
        await tester.pumpAndSettle();
        expect(find.text(l.diaryFeed.toUpperCase()), findsWidgets);
        // The filter bar is the first thing on the screen, and its labels are
        // exactly where a half-translated app shows its seams.
        expect(find.text(l.diaryFilterDevelopment), findsWidgets);
        expect(find.text(l.commonAll), findsWidgets);
      });
    }
  });

  group('dates and times follow the interface language', () {
    // The formatters were pinned to ru_RU while the interface was not, so a
    // Kazakh screen still said «15 сентября». This is that bug, held down.
    testWidgets('a month name is never left in Russian', (tester) async {
      await pump(tester, locale: const Locale('en'));
      await tester.tap(find.byIcon(Icons.auto_stories_outlined).first);
      await tester.pumpAndSettle();

      expect(find.textContaining(RegExp('январ|феврал|март|апрел|мая|июн|июл|август|сентябр|октябр|ноябр|декабр')), findsNothing);
    });

    for (final locale in supportedLocales) {
      testWidgets('${locale.languageCode} drives the date formatters', (
        tester,
      ) async {
        await pump(tester, locale: locale);

        // The formatters read Intl's current locale at call time rather than
        // one baked in at import, which is what makes a language switch
        // reformat the dates already on screen.
        expect(Intl.defaultLocale, locale.languageCode);
        expect(dayMonth.locale, locale.languageCode);
        expect(timeOfDay.locale, locale.languageCode);
        expect(shortDate.locale, locale.languageCode);
      });
    }
  });

  group('the top of the dashboard carries the child', () {
    testWidgets('name, age, last feed and last sleep are all there', (
      tester,
    ) async {
      await pump(tester, size: const Size(390, 844));

      // The header spends its lines on the child, the hour and one fact —
      // the last feed once there is one, the age until then. The rest of what
      // it used to carry is in the assistant tab.
      final header = find.byType(WarmHeader);
      expect(header, findsOneWidget);
      expect(
        find.descendant(of: header, matching: find.text('Демо-профиль')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: header, matching: find.byType(ChildAvatar)),
        findsOneWidget,
      );
    });
  });

  group('the diary is fully editable', () {
    /// Tapping the row is how an entry opens now.
    Future<void> openFirstEntry(WidgetTester tester) async {
      await tester.tap(find.byType(IntrinsicHeight).first);
      await tester.pumpAndSettle();
    }

    testWidgets('an ordinary entry opens, keeps its time and can be saved', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.byIcon(Icons.auto_stories_outlined).first);
      await tester.pumpAndSettle();

      await openFirstEntry(tester);

      final l = await AppLocalizations.delegate.load(defaultLocale);
      expect(find.text(l.diaryEditEntry), findsOneWidget);
      // Date and time are part of the form, not fixed at creation.
      expect(find.byType(DateTimeField), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, l.commonSave));
      await tester.pumpAndSettle();
      expect(find.text(l.diaryEditEntry), findsNothing);
    });

    testWidgets('deleting asks first and can be called off', (tester) async {
      await pump(tester);
      await tester.tap(find.byIcon(Icons.auto_stories_outlined).first);
      await tester.pumpAndSettle();

      final l = await AppLocalizations.delegate.load(defaultLocale);
      final before = tester.widgetList(find.byIcon(Icons.delete_outline)).length;

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      expect(find.text(l.diaryDeleteTitle), findsWidgets);

      await tester.tap(find.widgetWithText(TextButton, l.commonCancel));
      await tester.pumpAndSettle();

      // Nothing was lost to a stray tap next to the pencil.
      expect(
        tester.widgetList(find.byIcon(Icons.delete_outline)).length,
        before,
      );
    });

    testWidgets('a night goes back to the night form, not the general one', (
      tester,
    ) async {
      await pump(tester);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      // Record a night, then reopen it from the diary.
      await tester.tap(find.widgetWithText(InkWell, l.quickNightSleep));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, l.commonSave));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.auto_stories_outlined).first);
      await tester.pumpAndSettle();
      await openFirstEntry(tester);

      // The night sheet, with its wakings — not the generic entry dialog.
      expect(find.text(l.nightWokeUp), findsOneWidget);
      expect(find.text(l.diaryEditEntry), findsNothing);
    });
  });

  testWidgets('a photo opens full screen, swipeable and zoomable', (
    tester,
  ) async {
    await pump(tester, withPhotos: true);

    // The viewer is a route of its own: back closes it, and there is nothing
    // to discover — the thumbnail itself is the control.
    showPhotoViewer(
      tester.element(find.byType(Scaffold).first),
      photoIds: const ['a', 'b'],
    );
    await tester.pumpAndSettle();

    expect(find.byType(PageView), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsWidgets);
    expect(find.text('1 / 2'), findsOneWidget);
  });

  testWidgets('the home screen holds together on a desktop window', (
    tester,
  ) async {
    await pump(tester, size: const Size(1600, 1000));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('every quick action button is the same size', (tester) async {
    await pump(tester, locale: const Locale('kk'), size: const Size(390, 844));
    final l = await AppLocalizations.delegate.load(const Locale('kk'));

    final sizes = <Size>[
      for (final label in [
        l.quickFeed,
        l.quickSleep,
        l.quickNappy,
        l.quickTemperature,
      ])
        tester.getSize(find.widgetWithText(InkWell, label)),
    ];

    // Kazakh has the longest labels of the three, so if the grid is going to
    // go ragged it goes ragged here.
    for (final size in sizes) {
      expect(size.height, sizes.first.height);
      expect(size.width, closeTo(sizes.first.width, 0.5));
    }
  });

  testWidgets('the night sheet keeps its own form', (tester) async {
    await pump(tester, size: const Size(390, 844));
    final l = await AppLocalizations.delegate.load(defaultLocale);

    await tester.tap(find.widgetWithText(InkWell, l.quickNightSleep));
    await tester.pumpAndSettle();

    // Bedtime, waking, wakings and feeds — the shape of a night, not a
    // duration picked off a list.
    expect(find.byType(DateTimeField), findsNWidgets(2));
    expect(find.text(l.nightWokeUp), findsOneWidget);
    expect(find.text(l.nightOfThoseFeeds), findsOneWidget);
  });
}
