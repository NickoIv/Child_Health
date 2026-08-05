import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/core/analytics/shared_moments.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/data/family_repository.dart';
import 'package:child_health_tracker/features/family/moments_card.dart';
import 'package:child_health_tracker/features/shared/photo_widgets.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/models/photo.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Three photographs, a time, and a sentence.
///
/// Most of what is being checked here is what the card refuses to be: it is
/// not a feed, it does not appear for the mother, it does not appear at all on
/// a day with no photographs, and there is no way to add, react to or comment
/// on anything in it.
void main() {
  setUpAll(initializeDateFormatting);

  const pixel =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

  const fatherEmail = 'dad@example.com';
  const motherEmail = 'demo@example.com';
  final today = DateTime(2026, 8, 5, 20);

  final child = Child(
    id: 'c1',
    parentUid: 'mother-uid',
    name: 'Aisha',
    birthDate: DateTime(2025, 8, 2),
    gender: Gender.female,
  );

  DevelopmentLog log({
    required Duration ago,
    List<String> photos = const [],
    DateTime? at,
  }) => DevelopmentLog(
    id: 'l${ago.inMinutes}${photos.join()}',
    childId: child.id,
    date: (at ?? today).subtract(ago),
    type: LogType.note,
    title: 'x',
    photos: photos,
  );

  group('which photographs', () {
    test('are today\'s, newest first, and never more than three', () {
      final moments = recentMoments([
        log(ago: const Duration(hours: 1), photos: const ['newest']),
        log(ago: const Duration(hours: 3), photos: const ['middle', 'also']),
        log(ago: const Duration(hours: 6), photos: const ['oldest']),
      ], today);

      expect(moments, hasLength(momentsLimit));
      expect(
        [for (final m in moments) m.photoId],
        ['newest', 'middle', 'also'],
      );
      // The time shown is the entry's, which is the moment a parent
      // recognises — not whenever the file happened to be created.
      expect(moments.first.at, today.subtract(const Duration(hours: 1)));
    });

    test('are not yesterday\'s', () {
      // The digest above this card counts today. Pictures from last night
      // under a heading that says today would be the app contradicting
      // itself one card apart.
      final moments = recentMoments([
        log(ago: const Duration(days: 1, hours: 2), photos: const ['old']),
      ], today);

      expect(moments, isEmpty);
    });

    test('are the same photograph only once', () {
      final moments = recentMoments([
        log(ago: const Duration(hours: 1), photos: const ['a']),
        log(ago: const Duration(hours: 2), photos: const ['a', 'b']),
      ], today);

      expect([for (final m in moments) m.photoId], ['a', 'b']);
    });

    test('are nothing at all on a day with no pictures', () {
      final moments = recentMoments([
        log(ago: const Duration(hours: 1)),
        log(ago: const Duration(hours: 4)),
      ], today);

      expect(moments, isEmpty);
    });

    test('come from the entries that already exist', () {
      // No moments collection, no backfill, nothing to write when a photo is
      // uploaded — yesterday's entries produce yesterday's moments today.
      final logs = [log(ago: const Duration(hours: 1), photos: const ['a'])];
      expect(
        recentMoments(logs, today.subtract(const Duration(days: 1))),
        isEmpty,
      );
      expect(recentMoments(logs, today), hasLength(1));
    });
  });

  group('the caption', () {
    test('is chosen by how many are showing, and never at random', () {
      expect(lineFor(1), MomentLine.one);
      expect(lineFor(2), MomentLine.two);
      expect(lineFor(3), MomentLine.many);

      // The same count asked a hundred times is the same line, so the card
      // does not change under a parent who is looking at it.
      for (var i = 0; i < 100; i++) {
        expect(lineFor(2), MomentLine.two);
      }
    });

    test('the three sentences exist in all three languages', () async {
      for (final locale in supportedLocales) {
        final l = await AppLocalizations.delegate.load(locale);
        final lines = MomentLine.values.map((m) => momentLine(l, m)).toList();

        expect(lines.toSet().length, 3, reason: locale.languageCode);
        for (final line in lines) {
          expect(line.trim(), isNotEmpty, reason: locale.languageCode);
        }
      }
    });

    test('the English wording is the wording asked for', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      expect(momentLine(en, MomentLine.one), 'A small moment from today');
      expect(momentLine(en, MomentLine.two), 'Today brought a new smile');
      expect(momentLine(en, MomentLine.many), 'A memory worth keeping');
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

    /// Dated to now, because the card asks about today.
    List<DevelopmentLog> todaysPhotos(int count) {
      final now = DateTime.now();
      return [
        for (var i = 0; i < count; i++)
          log(
            at: now,
            ago: Duration(hours: i + 1),
            photos: ['p$i'],
          ),
      ];
    }

    testWidgets('the father gets the photographs, the time and the line', (
      tester,
    ) async {
      final family = await familyWithViewer();
      addTearDown(family.dispose);

      await pump(
        tester,
        family: family,
        email: fatherEmail,
        logs: todaysPhotos(2),
      );
      final l = await AppLocalizations.delegate.load(defaultLocale);

      expect(find.byType(MomentsCard), findsOneWidget);
      expect(find.text(l.momentsTitle), findsOneWidget);
      expect(find.descendant(
        of: find.byType(MomentsCard),
        matching: find.byType(PhotoThumb),
      ), findsNWidgets(2));
      // Two photographs, so the second of the three lines.
      expect(find.text(l.momentsLineTwo), findsOneWidget);
      expect(find.text(l.momentsLineOne), findsNothing);
    });

    testWidgets('four photographs today still show three', (tester) async {
      final family = await familyWithViewer();
      addTearDown(family.dispose);

      await pump(
        tester,
        family: family,
        email: fatherEmail,
        logs: todaysPhotos(4),
      );
      final l = await AppLocalizations.delegate.load(defaultLocale);

      expect(find.descendant(
        of: find.byType(MomentsCard),
        matching: find.byType(PhotoThumb),
      ), findsNWidgets(momentsLimit));
      expect(find.text(l.momentsLineMany), findsOneWidget);
    });

    testWidgets('no photographs today means no card at all', (tester) async {
      final family = await familyWithViewer();
      addTearDown(family.dispose);

      await pump(
        tester,
        family: family,
        email: fatherEmail,
        logs: [log(at: DateTime.now(), ago: const Duration(hours: 2))],
      );
      final l = await AppLocalizations.delegate.load(defaultLocale);

      // Not an empty frame explaining that nobody took a picture, which reads
      // as a small daily reproach.
      expect(find.text(l.momentsTitle), findsNothing);
      // Zero height — it takes the column's width the way any shrunk box does,
      // but occupies no vertical space between the cards above and below it.
      expect(tester.getSize(find.byType(MomentsCard)).height, 0);
    });

    testWidgets('the mother never sees it', (tester) async {
      final family = await familyWithViewer();
      addTearDown(family.dispose);

      await pump(
        tester,
        family: family,
        email: motherEmail,
        logs: todaysPhotos(3),
      );
      final l = await AppLocalizations.delegate.load(defaultLocale);

      // She took the photographs. Showing them back to her is not news.
      expect(find.text(l.momentsTitle), findsNothing);
      expect(find.text(l.momentsLineMany), findsNothing);
    });

    testWidgets('tapping one opens the viewer the diary already uses', (
      tester,
    ) async {
      final family = await familyWithViewer();
      addTearDown(family.dispose);

      await pump(
        tester,
        family: family,
        email: fatherEmail,
        logs: todaysPhotos(3),
      );

      await tester.tap(find.descendant(
        of: find.byType(MomentsCard),
        matching: find.byType(PhotoThumb),
      ).first);
      await tester.pumpAndSettle();

      // The viewer's own furniture: a counter, because all three were handed
      // over as one album and swiping reaches the other two.
      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('there is nothing on it to write, react or upload with', (
      tester,
    ) async {
      final family = await familyWithViewer();
      addTearDown(family.dispose);

      await pump(
        tester,
        family: family,
        email: fatherEmail,
        logs: todaysPhotos(3),
      );

      // A viewer is here to see the child, not to be handed a feed to perform
      // in. The one control on the card is the day's single thank-you, which
      // is a date rather than a message; everything below stays absent.
      final card = find.byType(MomentsCard);
      for (final icon in const [
        Icons.add_a_photo_outlined,
        Icons.camera_alt_outlined,
        Icons.chat_bubble_outline,
        Icons.send,
        Icons.reply,
      ]) {
        expect(
          find.descendant(of: card, matching: find.byIcon(icon)),
          findsNothing,
          reason: '$icon',
        );
      }
      expect(
        find.descendant(of: card, matching: find.byType(TextField)),
        findsNothing,
      );
    });
  });
}
