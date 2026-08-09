import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/core/care/teeth.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/core/l10n/labels.dart';
import 'package:child_health_tracker/features/growth/teeth_card.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Twenty milk teeth, and which of them are down.
///
/// What is tested is that the chart is derived from the diary rather than kept
/// beside it, that the published range is stated and never used to grade a
/// child, and that marking a tooth twice corrects the date instead of growing
/// a second tooth in the same socket.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeDateFormatting);

  final now = DateTime(2026, 8, 10, 12);

  final child = Child(
    id: 'c1',
    parentUid: 'p1',
    name: 'Aisha',
    birthDate: DateTime(2025, 8, 10),
    gender: Gender.female,
  );

  DevelopmentLog toothLog(String code, DateTime at, {String id = ''}) =>
      DevelopmentLog(
        id: id.isEmpty ? '$code$at' : id,
        childId: 'c1',
        date: at,
        type: LogType.milestone,
        title: LogTitles.tooth,
        tags: ['$toothTagPrefix$code'],
      );

  group('the table', () {
    test('is the twenty milk teeth and nothing else', () {
      expect(primaryTeeth, hasLength(20));
      expect(primaryTeeth.map((s) => s.code).toSet(), hasLength(20));

      // Ten in each jaw, five a side.
      for (final jaw in Jaw.values) {
        expect(primaryTeeth.where((s) => s.jaw == jaw), hasLength(10));
        for (final side in Side.values) {
          expect(
            primaryTeeth.where((s) => s.jaw == jaw && s.side == side),
            hasLength(5),
          );
        }
      }
    });

    test('every window opens before it closes, and the pairs agree', () {
      for (final slot in primaryTeeth) {
        expect(slot.fromMonths, lessThan(slot.toMonths), reason: slot.code);
        final twin = primaryTeeth.firstWhere(
          (s) => s.type == slot.type && s.jaw == slot.jaw && s.side != slot.side,
        );
        // Left and right of the same tooth arrive together.
        expect(twin.fromMonths, slot.fromMonths, reason: slot.code);
        expect(twin.toMonths, slot.toMonths, reason: slot.code);
      }
    });

    test('the lower central incisors come first, the upper second molars '
        'last', () {
      final earliest = primaryTeeth
          .map((s) => s.fromMonths)
          .reduce((a, b) => a < b ? a : b);
      final latest = primaryTeeth
          .map((s) => s.toMonths)
          .reduce((a, b) => a > b ? a : b);

      expect(
        primaryTeeth
            .where((s) => s.fromMonths == earliest)
            .every((s) => s.jaw == Jaw.lower &&
                s.type == ToothType.centralIncisor),
        isTrue,
      );
      expect(
        primaryTeeth
            .where((s) => s.toMonths == latest)
            .every((s) =>
                s.jaw == Jaw.upper && s.type == ToothType.secondMolar),
        isTrue,
      );
    });
  });

  group('what is expected', () {
    test('is nothing at all before the first window opens', () {
      final at3 = expectedTeethAt(3);
      expect(at3.fewest, 0);
      expect(at3.most, 0);
    });

    test('is a range rather than a number', () {
      // At ten months the two lower centrals are past their window and six
      // more have opened theirs — which is the honest answer to «сколько
      // должно быть».
      final at10 = expectedTeethAt(10);
      expect(at10.fewest, lessThan(at10.most));
      expect(at10.fewest, 2);
      expect(at10.most, 8);
    });

    test('is all twenty once the last window has closed', () {
      final at36 = expectedTeethAt(36);
      expect(at36.fewest, 20);
      expect(at36.most, 20);
    });
  });

  group('the chart', () {
    test('is read off the diary, not stored beside it', () {
      final erupted = teethIn([
        toothLog('lc-l', DateTime(2026, 2, 1)),
        toothLog('lc-r', DateTime(2026, 2, 20)),
      ]);

      expect(erupted.keys.toSet(), {'lc-l', 'lc-r'});
      expect(erupted['lc-l'], DateTime(2026, 2, 1));
    });

    test('ignores milestones that are not teeth', () {
      final erupted = teethIn([
        DevelopmentLog(
          id: 'm',
          childId: 'c1',
          date: now,
          type: LogType.milestone,
          title: 'Первое слово',
          tags: const ['речь'],
        ),
        // A tag that looks like one but names no slot in the table.
        toothLog('nonsense', now),
      ]);

      expect(erupted, isEmpty);
    });

    test('a slot written twice keeps the earlier date', () {
      // The second entry is a correction typed over a mistake, not a second
      // tooth in the same socket.
      final erupted = teethIn([
        toothLog('uc-l', DateTime(2026, 5, 10), id: 'a'),
        toothLog('uc-l', DateTime(2026, 4, 2), id: 'b'),
      ]);

      expect(erupted, hasLength(1));
      expect(erupted['uc-l'], DateTime(2026, 4, 2));
    });

    test('what comes next is the earliest slot still empty', () {
      final erupted = teethIn([
        toothLog('lc-l', DateTime(2026, 2, 1)),
        toothLog('lc-r', DateTime(2026, 2, 3)),
      ]);

      final next = nextExpected(erupted, 9);
      expect(next.first.jaw, Jaw.upper);
      expect(next.first.type, ToothType.centralIncisor);
    });

    test('and nothing comes next once all twenty are down', () {
      final erupted = {
        for (final slot in primaryTeeth) slot.code: DateTime(2026, 1, 1),
      };
      expect(nextExpected(erupted, 40), isEmpty);
    });
  });

  group('the name', () {
    test('is built from jaw, type and side in every language', () async {
      final slot = slotForCode('lc-l')!;
      for (final locale in supportedLocales) {
        final l = await AppLocalizations.delegate.load(locale);
        final name = toothName(l, slot);
        expect(name.trim(), isNotEmpty, reason: locale.languageCode);
        expect(name, contains(l.toothLower));
        expect(name, contains(l.toothCentralIncisor));
      }
    });

    test('a tooth on the timeline is named, not left as «Зуб»', () async {
      final l = await AppLocalizations.delegate.load(defaultLocale);
      final title = localizedLogTitle(l, toothLog('lc-l', now));

      expect(title, isNot(LogTitles.tooth));
      expect(title, contains('резец'));
    });
  });

  group('on the growth screen', () {
    Future<ProviderContainer> pump(
      WidgetTester tester, {
      List<DevelopmentLog> logs = const [],
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            childrenProvider.overrideWith((ref) => Stream.value([child])),
            logsProvider.overrideWith((ref) => Stream.value(logs)),
          ],
          child: const ChildHealthApp(),
        ),
      );
      await tester.pumpAndSettle();

      final l = await AppLocalizations.delegate.load(defaultLocale);
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.navGrowth));
      await tester.pumpAndSettle();

      return ProviderScope.containerOf(
        tester.element(find.byType(ChildHealthApp)),
      );
    }

    testWidgets('fits a phone and says nothing has come through yet', (
      tester,
    ) async {
      await pump(tester);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      await tester.dragUntilVisible(
        find.byType(TeethCard),
        find.byType(Scrollable).first,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      expect(find.text(l.teethNone), findsOneWidget);
    });

    testWidgets('a tap marks the tooth, and it lands in the diary', (
      tester,
    ) async {
      // On the live demo store: what is being tested is that the mark comes
      // back out of the repository it was written to, as a dated milestone.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const ProviderScope(child: ChildHealthApp()));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ChildHealthApp)),
      );
      final l = await AppLocalizations.delegate.load(defaultLocale);

      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.navGrowth));
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.byType(TeethCard),
        find.byType(Scrollable).first,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      // The lower arch, leftmost slot drawn — a second molar on the right.
      final teeth = find.descendant(
        of: find.byType(TeethCard),
        matching: find.byType(InkWell),
      );
      expect(teeth, findsNWidgets(20));
      await tester.tap(teeth.first);
      await tester.pumpAndSettle();

      await tester.tap(find.text(l.teethToday));
      await tester.pumpAndSettle();

      final logs = container.read(logsProvider).value!;
      final marked = logs.where((log) => toothOf(log) != null).toList();
      expect(marked, hasLength(1));
      expect(marked.single.type, LogType.milestone);
      expect(marked.single.title, LogTitles.tooth);
      expect(teethIn(logs), hasLength(1));
    });

    testWidgets('counts what is down and never grades the child', (
      tester,
    ) async {
      await pump(tester, logs: [
        toothLog('lc-l', DateTime(2026, 2, 1)),
        toothLog('lc-r', DateTime(2026, 2, 20)),
        toothLog('uc-l', DateTime(2026, 4, 2)),
      ]);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      await tester.dragUntilVisible(
        find.byType(TeethCard),
        find.byType(Scrollable).first,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      expect(find.text(l.teethCount(3)), findsOneWidget);

      // Scoped to this card: the growth chart beside it legitimately talks
      // about «нормы ВОЗ», and a screen-wide search would be testing that
      // card instead of this one.
      final card = find.byType(TeethCard);
      expect(
        find.descendant(of: card, matching: find.textContaining('обычно')),
        findsWidgets,
      );
      for (final word in ['отста', 'поздно', 'мало', 'норм', 'должн']) {
        expect(
          find.descendant(of: card, matching: find.textContaining(word)),
          findsNothing,
          reason: '«$word» has no business on this card',
        );
      }
    });
  });
}
