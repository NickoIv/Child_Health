import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/core/care/heavy_day.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/data/family_repository.dart';
import 'package:child_health_tracker/features/family/appreciation_card.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/models/family_member.dart';
import 'package:child_health_tracker/models/photo.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// A sentence on a hard day, and one heart a day from the other parent.
///
/// What is tested hardest is the ceiling on all of it: one sentence, once a
/// day, with no way to reply to it and nothing sent anywhere it was not asked
/// to go.
/// A moment earlier today, whatever time the suite happens to run at.
///
/// The obvious `DateTime.now().subtract(const Duration(hours: 1))` is a day
/// older than intended when the clock has just passed midnight, and every
/// card here asks about *today*. This spreads [count] moments across the part
/// of today that has already happened, so they are always today and always in
/// the past.
DateTime earlierToday(int index, int count) {
  final now = DateTime.now();
  final midnight = DateTime(now.year, now.month, now.day);
  final elapsed = now.difference(midnight).inMinutes;
  return midnight.add(Duration(minutes: elapsed * (index + 1) ~/ (count + 1)));
}

void main() {
  setUpAll(initializeDateFormatting);

  const pixel =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

  const motherEmail = 'demo@example.com';
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
    double? temperature,
    DateTime? from,
  }) => DevelopmentLog(
    id: '$type${ago.inMinutes}$minutes$wakings$temperature',
    childId: child.id,
    date: (from ?? today).subtract(ago),
    type: type,
    title: 'x',
    durationMinutes: minutes,
    nightWakings: wakings,
    metrics: Metrics(temperatureC: temperature),
  );

  group('what makes a day a hard one', () {
    test('ten entries do', () {
      final nine = [
        for (var i = 0; i < HeavyDayThresholds.events - 1; i++)
          log(LogType.feeding, ago: Duration(minutes: i * 30 + 5)),
      ];
      expect(wasHeavyDay(nine, today), isFalse);

      final ten = [
        ...nine,
        log(LogType.nappy, ago: const Duration(minutes: 2)),
      ];
      expect(wasHeavyDay(ten, today), isTrue);
    });

    test('four wake-ups do', () {
      expect(
        wasHeavyDay([
          log(LogType.sleep, ago: const Duration(hours: 14), minutes: 400,
              wakings: HeavyDayThresholds.nightWakings - 1),
        ], today),
        isFalse,
      );
      expect(
        wasHeavyDay([
          log(LogType.sleep, ago: const Duration(hours: 14), minutes: 400,
              wakings: HeavyDayThresholds.nightWakings),
        ], today),
        isTrue,
      );
    });

    test('last night counts even though it was entered yesterday', () {
      // A night is one block dated to the evening it began.
      expect(
        wasHeavyDay([
          log(LogType.sleep, ago: const Duration(days: 1, hours: 2),
              minutes: 420, wakings: 5),
        ], today),
        isTrue,
      );
    });

    test('a fever does', () {
      expect(
        wasHeavyDay([
          log(LogType.illness, ago: const Duration(hours: 3), temperature: 37.9),
        ], today),
        isFalse,
      );
      expect(
        wasHeavyDay([
          log(LogType.illness, ago: const Duration(hours: 3), temperature: 38.0),
        ], today),
        isTrue,
      );
    });

    test('an ordinary quiet day does not', () {
      expect(
        wasHeavyDay([
          log(LogType.feeding, ago: const Duration(hours: 2)),
          log(LogType.sleep, ago: const Duration(hours: 4), minutes: 90),
        ], today),
        isFalse,
      );
      expect(wasHeavyDay(const [], today), isFalse);
    });

    test('yesterday\'s hard day is not today\'s', () {
      final logs = [
        for (var i = 0; i < HeavyDayThresholds.events; i++)
          log(LogType.feeding, ago: Duration(days: 1, minutes: i * 30 + 5)),
      ];
      expect(wasHeavyDay(logs, today), isFalse);
    });
  });

  group('the thank-you', () {
    test('stores a date and a role, and nothing else', () async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);

      final invitation = await family.invite(
        childId: child.id,
        ownerUid: child.parentUid,
        email: fatherEmail,
      );
      await family.accept(invitation, 'father-uid');
      await family.thank(
        childId: child.id,
        email: fatherEmail,
        day: today,
      );

      final member = (await family.watchMembers(child.id).first).single;
      expect(member.thankedOn, '2026-08-05');
      expect(member.role, FamilyRole.viewer);
      // No message, no count, no history — there is nowhere for one to go.
      expect(member.toMap().keys, isNot(contains('message')));
      expect(member.toMap()['thanked_on'], '2026-08-05');
    });

    test('is one a day, and the date on the document says so', () async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);

      final invitation = await family.invite(
        childId: child.id,
        ownerUid: child.parentUid,
        email: fatherEmail,
      );
      await family.accept(invitation, 'father-uid');
      await family.thank(childId: child.id, email: fatherEmail, day: today);
      await family.thank(childId: child.id, email: fatherEmail, day: today);

      final member = (await family.watchMembers(child.id).first).single;
      expect(member.thankedOnDay(today), isTrue);
      // Sending twice on one day writes the same date again.
      expect(member.thankedOn, '2026-08-05');
      // And tomorrow it is a different day, so he may send again.
      expect(
        member.thankedOnDay(today.add(const Duration(days: 1))),
        isFalse,
      );
    });

    test('accepting an invitation does not lose one already sent', () async {
      final member = FamilyMember(
        email: fatherEmail,
        childId: child.id,
        ownerUid: child.parentUid,
        role: FamilyRole.viewer,
        status: InviteStatus.pending,
        invitedAt: today,
      ).thank(today);

      expect(member.accept('father-uid', today).thankedOn, '2026-08-05');
    });

    test('a day stamp is a calendar day and carries no clock', () {
      expect(dayStamp(DateTime(2026, 8, 5, 23, 59)), '2026-08-05');
      expect(dayStamp(DateTime(2026, 1, 1)), '2026-01-01');
    });
  });

  group('the wording', () {
    test('is the wording asked for, in all three languages', () async {
      final ru = await AppLocalizations.delegate.load(const Locale('ru'));
      expect(
        ru.appreciationHeavyDay,
        'Сегодня был непростой день. Вы сделали очень много для малыша.',
      );
      expect(ru.appreciationThanks, 'Папа поблагодарил вас за сегодняшний день ❤️');

      final kk = await AppLocalizations.delegate.load(const Locale('kk'));
      expect(
        kk.appreciationHeavyDay,
        'Бүгін оңай күн болмады. Сіз бала үшін өте көп нәрсе жасадыңыз.',
      );
      expect(kk.appreciationThanks, 'Әке бүгінгі күн үшін сізге алғыс айтты ❤️');

      final en = await AppLocalizations.delegate.load(const Locale('en'));
      expect(
        en.appreciationHeavyDay,
        'Today was not an easy day. You did a lot for your baby.',
      );
      expect(en.appreciationThanks, 'Dad thanked you for today ❤️');
    });

    test('advises nothing and diagnoses nothing', () async {
      // The sentence says a lot was done. The moment it suggests resting, asks
      // how she is, or mentions what a number might mean, the app is doing
      // something it is not qualified to do.
      const forbidden = [
        'отдохн', 'нужно', 'следует', 'врач', 'норм', 'стресс', 'депресс',
        'rest', 'should', 'doctor', 'normal', 'stress', 'consult',
      ];

      for (final locale in supportedLocales) {
        final l = await AppLocalizations.delegate.load(locale);
        final copy = [
          l.appreciationHeavyDay,
          l.appreciationThanks,
          l.appreciationThankButton,
        ].join(' ').toLowerCase();

        for (final word in forbidden) {
          expect(copy.contains(word), isFalse,
              reason: '«$word» in ${locale.languageCode}');
        }
      }
    });
  });

  group('on the screen', () {
    Future<void> pump(
      WidgetTester tester, {
      required FamilyRepository family,
      required String email,
      List<DevelopmentLog> logs = const [],
    }) async {
      tester.view.physicalSize = const Size(1000, 2000);
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

    /// A fixed handful of frames rather than `pumpAndSettle`, which waits for
    /// the whole app to go quiet and cannot on a screen that is still
    /// animating something of its own.
    Future<void> pumpFrames(WidgetTester tester) async {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
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

    /// A hard day, dated inside today so the card asking about today finds
    /// it however close to midnight the suite is running.
    List<DevelopmentLog> aHardDay() => [
      for (var i = 0; i < HeavyDayThresholds.events; i++)
        DevelopmentLog(
          id: 'hard$i',
          childId: child.id,
          date: earlierToday(i, HeavyDayThresholds.events),
          type: LogType.feeding,
          title: LogType.feeding.label,
        ),
    ];

    testWidgets('the mother gets the sentence after a hard day', (
      tester,
    ) async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);

      await pump(tester, family: family, email: motherEmail, logs: aHardDay());
      final l = await AppLocalizations.delegate.load(defaultLocale);

      expect(find.text(l.appreciationHeavyDay), findsOneWidget);
    });

    testWidgets('and nothing at all after an ordinary one', (tester) async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);

      await pump(
        tester,
        family: family,
        email: motherEmail,
        logs: [
          DevelopmentLog(
            id: 'quiet',
            childId: child.id,
            date: earlierToday(0, 1),
            type: LogType.feeding,
            title: LogType.feeding.label,
          ),
        ],
      );
      final l = await AppLocalizations.delegate.load(defaultLocale);

      expect(find.text(l.appreciationHeavyDay), findsNothing);
      // No height at all. A card that draws nothing at the top of a lazy list
      // is dropped from the tree outright, so absence and a zero height are
      // the same answer here.
      final card = find.byType(AppreciationCard);
      expect(card.evaluate().isEmpty ? 0.0 : tester.getSize(card).height, 0);
    });

    testWidgets('closing it puts it away for the rest of the day', (
      tester,
    ) async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);

      await pump(tester, family: family, email: motherEmail, logs: aHardDay());
      final l = await AppLocalizations.delegate.load(defaultLocale);

      expect(find.text(l.appreciationHeavyDay), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AppreciationCard),
          matching: find.byIcon(Icons.close),
        ),
      );
      await tester.pumpAndSettle();

      // Once a day. A sentence that returns on every visit to the dashboard
      // stops being kind by about the third time.
      expect(find.text(l.appreciationHeavyDay), findsNothing);
    });

    testWidgets('the father never gets the sentence', (tester) async {
      final family = await familyWithViewer();
      addTearDown(family.dispose);

      await pump(tester, family: family, email: fatherEmail, logs: aHardDay());
      final l = await AppLocalizations.delegate.load(defaultLocale);

      // It is addressed to the person who had the day.
      expect(find.text(l.appreciationHeavyDay), findsNothing);
    });

    testWidgets('the father sends one heart and the button closes', (
      tester,
    ) async {
      final family = await familyWithViewer();
      addTearDown(family.dispose);

      await pump(
        tester,
        family: family,
        email: fatherEmail,
        logs: [
          DevelopmentLog(
            id: 'p1',
            childId: child.id,
            date: earlierToday(0, 1),
            type: LogType.note,
            title: 'x',
            photos: const ['a'],
          ),
        ],
      );
      final l = await AppLocalizations.delegate.load(defaultLocale);

      expect(find.text(l.appreciationThankButton), findsOneWidget);
      await tester.tap(find.text(l.appreciationThankButton));
      await pumpFrames(tester);

      // One a day: the button is spent, and says so rather than vanishing.
      expect(find.text(l.appreciationThankSent), findsOneWidget);
      expect(find.text(l.appreciationThankButton), findsNothing);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(
              TextButton,
              l.appreciationThankSent,
            ))
            .onPressed,
        isNull,
      );
      // What was written is covered by the repository tests above; awaiting a
      // stream from inside a widget test would wait on a clock that only the
      // pump loop advances.
    });

    testWidgets('the mother sees that he thanked her', (tester) async {
      final family = await familyWithViewer();
      addTearDown(family.dispose);
      await family.thank(
        childId: child.id,
        email: fatherEmail,
        day: DateTime.now(),
      );

      await pump(tester, family: family, email: motherEmail);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      // On an ordinary day too: it was sent about this day, and holding it
      // back until the arithmetic agrees would overrule the person who sent it.
      expect(find.text(l.appreciationThanks), findsOneWidget);
      expect(find.text(l.appreciationHeavyDay), findsNothing);
    });

    testWidgets('yesterday\'s thanks is not shown today', (tester) async {
      final family = await familyWithViewer();
      addTearDown(family.dispose);
      await family.thank(
        childId: child.id,
        email: fatherEmail,
        day: DateTime.now().subtract(const Duration(days: 1)),
      );

      await pump(tester, family: family, email: motherEmail);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      expect(find.text(l.appreciationThanks), findsNothing);
    });

    testWidgets('there is nothing to type, reply to or react with', (
      tester,
    ) async {
      final family = await familyWithViewer();
      addTearDown(family.dispose);
      await family.thank(
        childId: child.id,
        email: fatherEmail,
        day: DateTime.now(),
      );

      await pump(tester, family: family, email: motherEmail, logs: aHardDay());

      // No chat, no comment, no field. What arrived is a date; there is
      // nothing here that could carry a reply back.
      final card = find.byType(AppreciationCard);
      expect(
        find.descendant(of: card, matching: find.byType(TextField)),
        findsNothing,
      );
      for (final icon in const [
        Icons.send,
        Icons.reply,
        Icons.chat_bubble_outline,
        Icons.favorite_border,
      ]) {
        expect(
          find.descendant(of: card, matching: find.byIcon(icon)),
          findsNothing,
          reason: '$icon',
        );
      }
    });
  });
}
