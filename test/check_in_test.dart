import 'package:child_health_tracker/core/care/check_in.dart';
import 'package:child_health_tracker/core/care/check_in_store.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/features/dashboard/check_in_card.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The one card addressed to the parent rather than about the child. Most of
/// what is tested is its restraint: only after a short night, only in the
/// morning, only once, and never a word that sounds like a diagnosis.
void main() {
  setUpAll(initializeDateFormatting);

  final morning = DateTime(2026, 8, 2, 8);

  DevelopmentLog night({
    required int minutes,
    int wakings = 1,
    Duration ago = const Duration(hours: 11),
  }) => DevelopmentLog(
    id: 'night$minutes$wakings$ago',
    childId: 'demo',
    date: morning.subtract(ago),
    type: LogType.sleep,
    title: 'Ночной сон',
    durationMinutes: minutes,
    nightWakings: wakings,
  );

  group('when it is asked', () {
    test('after a short night', () {
      expect(checkInDue([night(minutes: 240)], morning), isTrue);
    });

    test('after a broken one, however long', () {
      expect(
        checkInDue([night(minutes: 540, wakings: 4)], morning),
        isTrue,
      );
    });

    test('not after a night that went well', () {
      expect(
        checkInDue([night(minutes: 540, wakings: 1)], morning),
        isFalse,
      );
    });

    test('not before six or after noon', () {
      final logs = [night(minutes: 240)];

      expect(checkInDue(logs, DateTime(2026, 8, 2, 5)), isFalse);
      expect(checkInDue(logs, DateTime(2026, 8, 2, 6)), isTrue);
      expect(checkInDue(logs, DateTime(2026, 8, 2, 11, 59)), isTrue);
      expect(checkInDue(logs, DateTime(2026, 8, 2, 12)), isFalse);
      expect(checkInDue(logs, DateTime(2026, 8, 2, 23)), isFalse);
    });

    test('never at night', () {
      for (final hour in [0, 2, 4, 22, 23]) {
        expect(isMorning(DateTime(2026, 8, 2, hour)), isFalse, reason: '$hour');
      }
    });

    test('a night from last week is not this morning', () {
      expect(
        checkInDue(
          [night(minutes: 240, ago: const Duration(days: 4))],
          morning,
        ),
        isFalse,
      );
    });

    test('an ordinary nap is not a night', () {
      final nap = DevelopmentLog(
        id: 'nap',
        childId: 'demo',
        date: morning.subtract(const Duration(hours: 2)),
        type: LogType.sleep,
        title: 'Сон',
        durationMinutes: 40,
      );

      expect(checkInDue([nap], morning), isFalse);
    });

    test('once a day, whatever the answer was', () {
      expect(
        checkInDue([night(minutes: 240)], morning, shownDay: morning),
        isFalse,
      );
      // Tomorrow it may be asked again.
      expect(
        checkInDue(
          [
            night(
              minutes: 240,
              ago: const Duration(hours: 11),
            ),
          ],
          morning.add(const Duration(days: 1)),
          shownDay: morning,
        ),
        isFalse, // that night is a day old by then
      );
    });
  });

  group('what is stored', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('the day and the answer, and nothing else', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      await c
          .read(checkInStoreProvider.notifier)
          .answer(CheckInAnswer.tired, now: morning);

      expect(c.read(checkInStoreProvider)?.answer, CheckInAnswer.tired);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getKeys().where((k) => k.startsWith('check_in')).length,
        2,
      );
      expect(prefs.getString('check_in_answer'), 'tired');
    });

    test('being waved away records the day without an answer', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      await c.read(checkInStoreProvider.notifier).dismiss(now: morning);

      expect(c.read(checkInStoreProvider)?.answer, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('check_in_answer'), isNull);
      expect(prefs.getString('check_in_day'), isNotNull);
    });
  });

  group('the card', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<void> pump(
      WidgetTester tester, {
      List<DevelopmentLog>? logs,
      DateTime? at,
      Locale locale = defaultLocale,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            logsProvider.overrideWith(
              (ref) => Stream.value(logs ?? [night(minutes: 240)]),
            ),
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
            home: Scaffold(body: CheckInCard(now: at ?? morning)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('asks once, with three ways to answer', (tester) async {
      await pump(tester);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      expect(find.text(l.checkInTitle), findsOneWidget);
      expect(find.text(l.checkInHoldingUp), findsOneWidget);
      expect(find.text(l.checkInTired), findsOneWidget);
      expect(find.text(l.checkInVeryHard), findsOneWidget);
    });

    testWidgets('takes no room after a night that went well', (tester) async {
      await pump(tester, logs: [night(minutes: 540, wakings: 1)]);
      expect(tester.getSize(find.byType(CheckInCard)).height, 0);
    });

    for (final (answer, reply) in const [
      ('checkInHoldingUp', 'checkInReplyHoldingUp'),
      ('checkInTired', 'checkInReplyTired'),
      ('checkInVeryHard', 'checkInReplyVeryHard'),
    ]) {
      testWidgets('$answer gets its own line back, and the buttons go', (
        tester,
      ) async {
        await pump(tester);
        final l = await AppLocalizations.delegate.load(defaultLocale);

        final labels = {
          'checkInHoldingUp': l.checkInHoldingUp,
          'checkInTired': l.checkInTired,
          'checkInVeryHard': l.checkInVeryHard,
        };
        final replies = {
          'checkInReplyHoldingUp': l.checkInReplyHoldingUp,
          'checkInReplyTired': l.checkInReplyTired,
          'checkInReplyVeryHard': l.checkInReplyVeryHard,
        };

        await tester.tap(find.text(labels[answer]!));
        await tester.pumpAndSettle();

        expect(find.text(replies[reply]!), findsOneWidget);
        expect(find.text(l.checkInTitle), findsNothing);
        expect(find.text(l.checkInHoldingUp), findsNothing);
      });
    }

    testWidgets('the cross puts it away for the day', (tester) async {
      await pump(tester);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text(l.checkInTitle), findsNothing);
      expect(tester.getSize(find.byType(CheckInCard)).height, 0);
    });

    testWidgets('it speaks whichever language the app is in', (tester) async {
      for (final locale in supportedLocales) {
        await pump(tester, locale: locale);
        final l = await AppLocalizations.delegate.load(locale);

        expect(
          find.text(l.checkInTitle),
          findsOneWidget,
          reason: locale.languageCode,
        );
      }
    });
  });

  test('nothing in the wording names a condition or sends her to a doctor',
      () async {
    // The card acknowledges a hard night. The moment it starts naming things
    // it has become something this app is in no position to be.
    const forbidden = [
      'депресс', 'тревожн', 'расстройств', 'диагноз', 'врач', 'психолог',
      'симптом', 'лечен', 'норм',
      'depress', 'anxiet', 'disorder', 'diagnos', 'doctor', 'therapist',
      'symptom', 'treatment',
      'дәрігер', 'депресс', 'психолог',
    ];

    for (final locale in supportedLocales) {
      final l = await AppLocalizations.delegate.load(locale);
      final copy = [
        l.checkInTitle,
        l.checkInHoldingUp,
        l.checkInTired,
        l.checkInVeryHard,
        l.checkInReplyHoldingUp,
        l.checkInReplyTired,
        l.checkInReplyVeryHard,
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
}
