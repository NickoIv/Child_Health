import 'package:child_health_tracker/core/care/suggestion_store.dart';
import 'package:child_health_tracker/core/care/suggestions.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/features/dashboard/suggestion_card.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A card that appears on its own has to earn it every time. Most of what is
/// tested here is when it stays away: at night, after it has been dismissed,
/// when the feed it would suggest has already been recorded, and when there is
/// nothing in the history to reason from.
void main() {
  setUpAll(initializeDateFormatting);

  /// Mid-afternoon, well clear of the quiet hours.
  final now = DateTime(2026, 8, 2, 15);

  DevelopmentLog log(
    LogType type, {
    required Duration ago,
    int? minutes,
    NappyKind? nappy,
  }) => DevelopmentLog(
    id: '$type$ago',
    childId: 'demo',
    date: now.subtract(ago),
    type: type,
    title: 'x',
    durationMinutes: minutes,
    nappyKind: nappy,
  );

  /// A nap that ended half an hour ago.
  List<DevelopmentLog> justWoke() => [
    log(LogType.sleep, ago: const Duration(minutes: 90), minutes: 60),
  ];

  group('after a nap', () {
    test('is suggested once the child has been awake a little while', () {
      expect(suggestionFor(justWoke(), now), SuggestionKind.afterSleep);
    });

    test('not while the nap is still running', () {
      final asleep = [
        log(LogType.sleep, ago: const Duration(minutes: 20), minutes: 120),
      ];
      expect(suggestionFor(asleep, now), isNull);
    });

    test('not in the first minutes after waking', () {
      final barelyAwake = [
        log(LogType.sleep, ago: const Duration(minutes: 65), minutes: 60),
      ];
      expect(suggestionFor(barelyAwake, now), isNull);
    });

    test('not hours later — the moment has passed', () {
      final longAgo = [
        log(LogType.sleep, ago: const Duration(hours: 5), minutes: 60),
      ];
      expect(suggestionFor(longAgo, now), isNull);
    });

    test('not once she has already fed', () {
      final fed = [
        ...justWoke(),
        log(LogType.feeding, ago: const Duration(minutes: 10)),
      ];
      expect(suggestionFor(fed, now), isNull);
    });

    test('a feed from before the nap does not count', () {
      final fedEarlier = [
        ...justWoke(),
        log(LogType.feeding, ago: const Duration(hours: 3)),
      ];
      expect(suggestionFor(fedEarlier, now), SuggestionKind.afterSleep);
    });
  });

  group('nappies', () {
    test('a quiet stretch is worth mentioning', () {
      final quiet = [
        log(LogType.nappy, ago: const Duration(hours: 5),
            nappy: NappyKind.wet),
      ];
      expect(suggestionFor(quiet, now), SuggestionKind.nappy);
    });

    test('a recent one is not', () {
      final recent = [
        log(LogType.nappy, ago: const Duration(hours: 2),
            nappy: NappyKind.wet),
      ];
      expect(suggestionFor(recent, now), isNull);
    });

    test('never having logged one at all is not a gap', () {
      // She does not use this part of the app. That is her business.
      expect(suggestionFor(const [], now), isNull);
    });
  });

  group('the rules that hold it back', () {
    test('only ever one at a time, and the nap comes first', () {
      final both = [
        ...justWoke(),
        log(LogType.nappy, ago: const Duration(hours: 6),
            nappy: NappyKind.wet),
      ];
      expect(suggestionFor(both, now), SuggestionKind.afterSleep);
    });

    test('nothing between ten at night and six in the morning', () {
      for (final hour in [22, 23, 0, 3, 5]) {
        final night = DateTime(2026, 8, 2, hour);
        expect(isQuietHour(night), isTrue, reason: '$hour:00');
        expect(
          suggestionFor(
            [log(LogType.sleep, ago: const Duration(minutes: 90), minutes: 60)],
            night,
          ),
          isNull,
          reason: 'at $hour:00 a parent needs no opinions',
        );
      }
    });

    test('six in the morning is no longer night', () {
      expect(isQuietHour(DateTime(2026, 8, 2, 6)), isFalse);
      expect(isQuietHour(DateTime(2026, 8, 2, 21, 59)), isFalse);
    });

    test('a dismissal holds for six hours and then lets go', () {
      final until = now.add(dismissDuration);
      final dismissed = {SuggestionKind.afterSleep: until};

      expect(
        suggestionFor(justWoke(), now, dismissedUntil: dismissed),
        isNull,
      );
      // Six hours on, the same rule may speak again.
      expect(
        suggestionFor(
          [log(LogType.sleep, ago: const Duration(minutes: 90), minutes: 60)],
          until.add(const Duration(minutes: 1)),
          dismissedUntil: dismissed,
        ),
        isNull, // the nap itself is stale by then
      );
      expect(until.difference(now), const Duration(hours: 6));
    });

    test('dismissing one kind does not silence the other', () {
      final both = [
        ...justWoke(),
        log(LogType.nappy, ago: const Duration(hours: 6),
            nappy: NappyKind.wet),
      ];
      expect(
        suggestionFor(
          both,
          now,
          dismissedUntil: {
            SuggestionKind.afterSleep: now.add(const Duration(hours: 1)),
          },
        ),
        SuggestionKind.nappy,
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
            home: Scaffold(body: SuggestionCard(now: at ?? now)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('says nothing when there is nothing to say', (tester) async {
      await pump(tester, logs: const []);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('offers both ways to record it', (tester) async {
      await pump(tester, logs: justWoke());
      final l = await AppLocalizations.delegate.load(defaultLocale);

      expect(find.text(l.suggestionAfterSleep), findsOneWidget);
      expect(find.text(l.quickTimeNow), findsOneWidget);
      expect(find.text(l.quickTimeChoose), findsOneWidget);
    });

    testWidgets('«Сейчас» opens the feed straight at its options', (
      tester,
    ) async {
      await pump(tester, logs: justWoke());
      final l = await AppLocalizations.delegate.load(defaultLocale);

      await tester.tap(find.text(l.quickTimeNow));
      await tester.pumpAndSettle();

      // Past the sheet's own "now or then" question, which the card asked.
      expect(find.text(l.feedingLeft), findsOneWidget);
    });

    testWidgets('«Выбрать время» opens it on the date and the note', (
      tester,
    ) async {
      await pump(tester, logs: justWoke());
      final l = await AppLocalizations.delegate.load(defaultLocale);

      await tester.tap(find.text(l.quickTimeChoose));
      await tester.pumpAndSettle();

      expect(find.textContaining(l.quickNoteOptional), findsOneWidget);
    });

    testWidgets('the cross puts it away', (tester) async {
      await pump(tester, logs: justWoke());
      final l = await AppLocalizations.delegate.load(defaultLocale);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text(l.suggestionAfterSleep), findsNothing);
    });

    testWidgets('it speaks whichever language the app is in', (tester) async {
      for (final locale in supportedLocales) {
        await pump(tester, logs: justWoke(), locale: locale);
        final l = await AppLocalizations.delegate.load(locale);

        expect(
          find.text(l.suggestionAfterSleep),
          findsOneWidget,
          reason: locale.languageCode,
        );
      }
    });
  });
}
