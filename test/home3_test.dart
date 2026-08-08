import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/core/l10n/labels.dart';
import 'package:child_health_tracker/core/theme/app_theme.dart';
import 'package:child_health_tracker/core/theme/motion.dart';
import 'package:child_health_tracker/features/dashboard/focus_home.dart';
import 'package:child_health_tracker/features/family/family_screen.dart';
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

/// Home 3.0: the shape of the screen, and what is no longer on it.
void main() {
  setUpAll(initializeDateFormatting);

  const pixel =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

  final child = Child(
    id: 'c1',
    parentUid: 'demo-uid',
    name: 'Aisha',
    birthDate: DateTime(2025, 8, 2),
    gender: Gender.female,
  );

  Future<void> pump(
    WidgetTester tester, {
    List<DevelopmentLog>? logs,
    Size size = const Size(390, 1400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          childrenProvider.overrideWith((ref) => Stream.value([child])),
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
          if (logs != null)
            logsProvider.overrideWith((ref) => Stream.value(logs)),
        ],
        child: const ChildHealthApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the top of the screen', () {
    testWidgets('the header carries the child and one figure', (
      tester,
    ) async {
      await pump(tester);
      final l = await AppLocalizations.delegate.load(defaultLocale);
      final header = find.byType(WarmHeader);

      expect(header, findsOneWidget);
      expect(
        find.descendant(of: header, matching: find.text(child.name)),
        findsOneWidget,
      );
      // The name at the header size, and it is the largest thing on the
      // screen: everything under it is a label or a figure.
      final name = tester.widget<Text>(
        find.descendant(of: header, matching: find.text(child.name)),
      );
      expect(name.style?.fontSize, AppTheme.headerSize);

      // The question the screen exists to answer, printed as a caps label
      // with a figure under it rather than as a grey sentence.
      expect(
        find.descendant(
          of: header,
          matching: find.text(l.nowLastFeeding.toUpperCase()),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: header,
          matching: find.text(greetingFor(l, DateTime.now())),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the age shares a line with the date, under the name', (
      tester,
    ) async {
      await pump(tester);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      // It used to sit on a peach chip, which made the one thing in the
      // header that is not tappable look like the one thing that is.
      final age = find.descendant(
        of: find.byType(WarmHeader),
        matching: find.textContaining(localizedAge(l, child)),
      );
      expect(age, findsOneWidget);

      final line = tester.widget<Text>(age);
      expect(line.data, contains('·'));
      expect(line.style?.fontSize, AppTheme.secondarySize);
    });

    testWidgets('the actions are a two by two square of 112px cards', (
      tester,
    ) async {
      await pump(tester);

      final cards = find.byType(ActionCard);
      expect(cards, findsNWidgets(4));

      final boxes = [
        for (final e in cards.evaluate()) tester.getRect(find.byWidget(e.widget)),
      ];
      for (final box in boxes) {
        expect(box.height, ActionCard.height);
      }
      expect(ActionCard.height, 112);
      expect(ActionCard.radius, Warm.cardRadius);
      expect(ActionCard.iconSize, 21);
      expect(ActionCard.titleSize, 17);
      expect(ActionCard.captionSize, 12);

      // Two rows of two: the first two share a top, and the third starts
      // lower than the first.
      expect(boxes[0].top, boxes[1].top);
      expect(boxes[2].top, boxes[3].top);
      expect(boxes[2].top, greaterThan(boxes[0].top));
    });
  });

  group('the recent events', () {
    testWidgets('are a rail of at most three, with a photograph where there '
        'is one', (tester) async {
      final now = DateTime.now();
      await pump(
        tester,
        logs: [
          DevelopmentLog(
            id: 'p',
            childId: child.id,
            date: now.subtract(const Duration(minutes: 5)),
            type: LogType.milestone,
            title: 'Первая улыбка',
            photos: const ['a'],
          ),
          for (var i = 0; i < 5; i++)
            DevelopmentLog(
              id: 'f$i',
              childId: child.id,
              date: now.subtract(Duration(minutes: 30 * i + 30)),
              type: LogType.feeding,
              title: LogType.feeding.label,
              feedingSide: FeedingSide.left,
              durationMinutes: 15,
            ),
        ],
      );

      final rail = find.byType(RecentPreview);
      // Three events, and the photograph rides along with the entry it
      // belongs to rather than with the row that happens to be first.
      expect(
        find.descendant(of: rail, matching: find.byType(PhotoThumb)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: rail, matching: find.text('Первая улыбка')),
        findsOneWidget,
      );
      // Time, title and the short detail under it.
      expect(
        find.descendant(of: rail, matching: find.textContaining('Левая')),
        findsWidgets,
      );
    });

    testWidgets('each carries a ring of its own, not a shared thread', (
      tester,
    ) async {
      await pump(
        tester,
        logs: [
          for (var i = 0; i < 3; i++)
            DevelopmentLog(
              id: 'f$i',
              childId: child.id,
              date: DateTime.now().subtract(Duration(minutes: 30 * i + 5)),
              type: LogType.feeding,
              title: LogType.feeding.label,
            ),
        ],
      );

      // Three entries, three dots, each in the colour of its own type. They
      // used to be three identical orange rings, which said only "this is an
      // entry" — something the row already said by existing.
      final dots = find
          .descendant(
            of: find.byType(RecentPreview),
            matching: find.byWidgetPredicate((w) {
              if (w is! Container) return false;
              final d = w.decoration;
              return d is BoxDecoration && d.shape == BoxShape.circle;
            }),
          )
          .evaluate();

      expect(dots, hasLength(3));
      final brightness = Theme.of(
        tester.element(find.byType(RecentPreview)),
      ).brightness;
      for (final dot in dots) {
        final box = dot.widget as Container;
        expect(
          (box.decoration! as BoxDecoration).color,
          logColor(
            DevelopmentLog(
              id: 'x',
              childId: child.id,
              date: DateTime.now(),
              type: LogType.feeding,
              title: LogType.feeding.label,
            ),
            brightness,
          ),
        );
        expect(tester.getSize(find.byWidget(box)).width, 8);
      }
    });
  });

  group('where the microphone was', () {
    testWidgets('there is nothing above the tab bar', (tester) async {
      // «На странице Обзор убери микрофон и отдай эти функции ИИ.» A card with
      // a field, a microphone and two lines of instructions used to sit here,
      // on top of whatever screen was being read.
      await pump(tester);

      expect(find.byIcon(Icons.mic), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);

      // And the events reach the tab bar, which is the space the card was
      // taking on a screen opened forty times a day.
      final bar = tester.getRect(find.byType(NavigationBar));
      expect(
        tester.getRect(find.byType(RecentPreview)).bottom,
        lessThan(bar.bottom),
      );
    });

    testWidgets('the way in is the assistant, last under a right thumb', (
      tester,
    ) async {
      await pump(tester, size: const Size(390, 900));
      final l = await AppLocalizations.delegate.load(defaultLocale);

      final ask = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(l.navAsk),
      );
      expect(ask, findsOneWidget);

      // Rightmost of the destinations: the same sentence is written down or
      // answered there, and it is one tap from every screen.
      final bar = tester.getRect(find.byType(NavigationBar));
      expect(tester.getRect(ask).center.dx, greaterThan(bar.center.dx));
    });
  });

  group('the tabs', () {
    testWidgets('are home, history, assistant and family', (tester) async {
      await pump(tester, size: const Size(390, 900));
      final l = await AppLocalizations.delegate.load(defaultLocale);

      final bar = find.byType(NavigationBar);
      expect(bar, findsOneWidget);
      for (final label in [
        l.navDashboard,
        l.navDiary,
        l.navAssistant,
        l.navFamily,
      ]) {
        expect(
          find.descendant(of: bar, matching: find.text(label)),
          findsOneWidget,
          reason: label,
        );
      }
    });

    testWidgets('the family tab is where the family lives', (tester) async {
      await pump(tester, size: const Size(390, 900));
      final l = await AppLocalizations.delegate.load(defaultLocale);

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(l.navFamily),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FamilyScreen), findsOneWidget);
      // Scoped: the tab is called the same thing the card is, which is the
      // point of moving it out of settings.
      expect(
        find.descendant(
          of: find.byType(FamilyScreen),
          matching: find.text(l.familyTitle),
        ),
        findsOneWidget,
      );
    });
  });

  group('the motion', () {
    test('is one curve and four durations', () {
      expect(Motion.curve, Curves.easeOutCubic);
      expect(Pressable.pressedScale, 0.97);
      expect(Pressable.duration, const Duration(milliseconds: 110));
      expect(Arrival.rise, 8.0);
      expect(Arrival.duration, const Duration(milliseconds: 260));
    });

    test('the palette is the one asked for', () {
      expect(Warm.background, const Color(0xFFFAF7F4));
      expect(Warm.primaryCard, const Color(0xFFFFFFFF));
      expect(Warm.accent, const Color(0xFFE67E22));
      expect(Warm.lavender, const Color(0xFFF3EAFE));
      expect(Warm.ink, const Color(0xFF1E1A18));
      expect(Warm.inkSoft, const Color(0xFF6E645F));
      // Soft rather than absent: a cream page with a hard shadow reads as
      // dirty, one with none reads as a wireframe, and one with a single
      // wide blur — which is what this was — reads as fog.
      final shadow = Warm.shadow(Brightness.light);
      expect(shadow, hasLength(2));
      expect(shadow.first.blurRadius, lessThan(4), reason: 'the edge');
      expect(shadow.last.blurRadius, 22, reason: 'the lift');
      expect(shadow.last.color.a, closeTo(0.07, 0.005));
      expect(Warm.shadow(Brightness.dark), isEmpty);
    });
  });
}
