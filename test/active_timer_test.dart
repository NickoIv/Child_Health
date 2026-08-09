import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/core/analytics/daily_care.dart';
import 'package:child_health_tracker/core/care/active_timer.dart';
import 'package:child_health_tracker/features/dashboard/timer_card.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A feed and a sleep, measured rather than remembered.
///
/// What is tested is the whole reason the timer exists: that the number
/// written down is the one the clock counted, that it survives the reload a
/// web app takes whenever the phone reclaims memory, and that a clock left
/// running says so instead of quietly filing nine hours at the breast.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeDateFormatting);

  final start = DateTime(2026, 8, 9, 14, 32);

  ActiveTimer feeding({FeedingSide side = FeedingSide.left}) => ActiveTimer(
    kind: TimerKind.feeding,
    childId: 'c1',
    startedAt: start,
    side: side,
  );

  group('what the clock measured', () {
    test('is rounded to the nearest minute and never to nothing', () {
      final t = feeding();
      // A latch that lasted forty seconds happened.
      expect(t.minutesAt(start), 1);
      expect(t.minutesAt(start.add(const Duration(seconds: 40))), 1);
      // Rounded, not truncated: 14:31 of feeding is a quarter of an hour.
      expect(t.minutesAt(start.add(const Duration(seconds: 14 * 60 + 31))), 15);
      expect(t.minutesAt(start.add(const Duration(seconds: 14 * 60 + 29))), 14);
      expect(t.minutesAt(start.add(const Duration(hours: 1, minutes: 5))), 65);
    });

    test('never runs backwards', () {
      // A timezone change, an NTP correction or a parent fixing the date.
      // None of them is a feed of minus twenty minutes.
      expect(feeding().elapsed(start.subtract(const Duration(hours: 3))),
          Duration.zero);
      expect(feeding().minutesAt(start.subtract(const Duration(hours: 3))), 1);
    });

    test('reads as a clock, and grows an hours column only when it has one',
        () {
      expect(clockText(const Duration(seconds: 8)), '00:08');
      expect(clockText(const Duration(minutes: 12, seconds: 4)), '12:04');
      expect(clockText(const Duration(minutes: 59, seconds: 59)), '59:59');
      expect(clockText(const Duration(hours: 1, minutes: 2, seconds: 30)),
          '1:02:30');
    });

    test('says when it has probably been left running', () {
      final f = feeding();
      expect(f.looksForgotten(start.add(const Duration(minutes: 40))), isFalse);
      expect(f.looksForgotten(start.add(const Duration(hours: 2))), isTrue);

      // A night is long. Sixteen hours is not a night.
      final s = ActiveTimer(
        kind: TimerKind.sleep,
        childId: 'c1',
        startedAt: start,
      );
      expect(s.looksForgotten(start.add(const Duration(hours: 11))), isFalse);
      expect(s.looksForgotten(start.add(const Duration(hours: 16))), isTrue);
    });
  });

  group('the running clock', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('is written down the moment it starts, and read back after a reload',
        () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      await c.read(activeTimerProvider.notifier).start(
            kind: TimerKind.feeding,
            childId: 'c1',
            side: FeedingSide.right,
            now: start,
          );

      // A second container is what a reload looks like from here: nothing in
      // memory, everything on disk.
      final reloaded = ProviderContainer();
      addTearDown(reloaded.dispose);
      reloaded.read(activeTimerProvider);
      await Future<void>.delayed(Duration.zero);

      final restored = reloaded.read(activeTimerProvider);
      expect(restored, isNotNull);
      expect(restored!.kind, TimerKind.feeding);
      expect(restored.side, FeedingSide.right);
      expect(restored.startedAt, start);
      expect(restored.childId, 'c1');
    });

    test('leaves nothing behind when it is stopped', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      await c
          .read(activeTimerProvider.notifier)
          .start(kind: TimerKind.sleep, childId: 'c1', now: start);
      final stopped = await c.read(activeTimerProvider.notifier).stop();

      expect(stopped?.kind, TimerKind.sleep);
      expect(c.read(activeTimerProvider), isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys().where((k) => k.startsWith('active_timer')), isEmpty);
    });

    test('a second start replaces the first rather than refusing it', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(activeTimerProvider.notifier);

      await notifier.start(
        kind: TimerKind.feeding,
        childId: 'c1',
        side: FeedingSide.left,
        now: start,
      );
      await notifier.start(kind: TimerKind.sleep, childId: 'c1', now: start);

      expect(c.read(activeTimerProvider)!.kind, TimerKind.sleep);
      // The side went with the feed it belonged to.
      expect(c.read(activeTimerProvider)!.side, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('active_timer_side'), isNull);
    });
  });

  group('which breast was last', () {
    DevelopmentLog feed(FeedingSide side, DateTime at) => DevelopmentLog(
      id: '$side$at',
      childId: 'c1',
      date: at,
      type: LogType.feeding,
      title: LogType.feeding.label,
      feedingSide: side,
    );

    test('is answered across midnight, where the question is actually asked',
        () {
      // Two in the morning: one feed today, the one before it yesterday.
      // Newest first, as the repository hands them over.
      final logs = [
        feed(FeedingSide.left, DateTime(2026, 8, 9, 2, 10)),
        feed(FeedingSide.right, DateTime(2026, 8, 8, 23, 40)),
      ];
      expect(lastFeedingIn(logs)?.feedingSide, FeedingSide.left);

      // Half past midnight, and the last feed was forty minutes ago and
      // yesterday. The day's own tally stops at midnight, which is exactly
      // why it cannot answer this one.
      final overnight = [feed(FeedingSide.right, DateTime(2026, 8, 8, 23, 40))];
      expect(lastFeedingIn(overnight)?.feedingSide, FeedingSide.right);
      expect(dailyCareFor(overnight, DateTime(2026, 8, 9, 0, 30)).feedings, 0);
    });

    test('is nothing at all when there is no feed on record', () {
      expect(lastFeedingIn(const []), isNull);
      expect(
        lastFeedingIn([
          DevelopmentLog(
            id: 'n',
            childId: 'c1',
            date: start,
            type: LogType.nappy,
            title: LogType.nappy.label,
            nappyKind: NappyKind.wet,
          ),
        ]),
        isNull,
      );
    });
  });

  group('on the home screen', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    /// [pumpAndSettle] is no use once a clock is on screen: the card schedules
    /// a frame every second for as long as it runs, so settling never
    /// finishes. Pumping a fixed number of frames is what a running app does.
    Future<void> beat(WidgetTester tester, [int frames = 10]) async {
      for (var i = 0; i < frames; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
    }

    Future<ProviderContainer> pumpApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const ProviderScope(child: ChildHealthApp()));
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(
        tester.element(find.byType(ChildHealthApp)),
      );
    }

    testWidgets('nothing is drawn while nothing is being measured', (
      tester,
    ) async {
      await pumpApp(tester);
      expect(find.byType(RunningTimerCard), findsOneWidget);
      expect(find.text('Записать'), findsNothing);
    });

    testWidgets('«Засечь время» on a feed asks the side and starts counting', (
      tester,
    ) async {
      final container = await pumpApp(tester);

      await tester.tap(find.widgetWithText(InkWell, 'Покормила'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Засечь время'));
      await tester.pumpAndSettle();

      // The same three buttons as recording one, because the only thing still
      // missing is the side.
      expect(find.widgetWithText(FilledButton, 'Левая'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Левая'));
      await beat(tester);

      final timer = container.read(activeTimerProvider);
      expect(timer, isNotNull);
      expect(timer!.kind, TimerKind.feeding);
      expect(timer.side, FeedingSide.left);
      // Started, not recorded: nothing is in the diary until it is stopped.
      expect(find.text('Отсчёт пошёл'), findsOneWidget);
    });

    testWidgets('a sleep needs no second question', (tester) async {
      final container = await pumpApp(tester);

      await tester.tap(find.widgetWithText(InkWell, 'Поспал'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Засечь время'));
      await beat(tester);

      expect(container.read(activeTimerProvider)?.kind, TimerKind.sleep);
    });

    testWidgets('the card counts, and writes down what it counted', (
      tester,
    ) async {
      final container = await pumpApp(tester);
      final child = container.read(selectedChildProvider)!;

      await container.read(activeTimerProvider.notifier).start(
            kind: TimerKind.feeding,
            childId: child.id,
            side: FeedingSide.right,
            now: DateTime.now().subtract(const Duration(minutes: 12)),
          );
      await beat(tester);

      expect(find.text('КОРМЛЕНИЕ ИДЁТ'), findsOneWidget);
      expect(find.textContaining('Правая'), findsWidgets);
      // Twelve minutes and some seconds, ticking. Scoped to the card: the
      // list of the day's entries below it is full of times reading «12:42».
      expect(
        find.descendant(
          of: find.byType(RunningTimerCard),
          matching: find.byWidgetPredicate(
            (w) => w is Text && (w.data ?? '').startsWith('12:'),
          ),
        ),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Записать'));
      await beat(tester);

      expect(container.read(activeTimerProvider), isNull);
      final logs = container.read(logsProvider).value!;
      final written = logs.firstWhere((l) => l.durationMinutes == 12);
      expect(written.type, LogType.feeding);
      expect(written.feedingSide, FeedingSide.right);
      // Dated where it began: a feed that ran from 14:32 happened at 14:32.
      expect(
        DateTime.now().difference(written.date).inMinutes,
        greaterThanOrEqualTo(12),
      );
    });

    testWidgets('a clock left running says so rather than filing it quietly', (
      tester,
    ) async {
      final container = await pumpApp(tester);
      final child = container.read(selectedChildProvider)!;

      await container.read(activeTimerProvider.notifier).start(
            kind: TimerKind.feeding,
            childId: child.id,
            side: FeedingSide.left,
            now: DateTime.now().subtract(const Duration(hours: 3)),
          );
      await beat(tester);

      expect(find.textContaining('забыли остановить'), findsOneWidget);

      // And it can be thrown away without becoming a three-hour feed.
      await tester.tap(find.text('Сбросить'));
      await beat(tester);

      expect(container.read(activeTimerProvider), isNull);
      expect(
        container.read(logsProvider).value!.any((l) => l.durationMinutes == 180),
        isFalse,
      );
    });

    testWidgets('the feeding sheet says which breast was last', (tester) async {
      final container = await pumpApp(tester);
      final child = container.read(selectedChildProvider)!;

      await container.read(logRepositoryProvider).add(
            DevelopmentLog(
              id: '',
              childId: child.id,
              date: DateTime.now().subtract(const Duration(hours: 2)),
              type: LogType.feeding,
              title: LogType.feeding.label,
              feedingSide: FeedingSide.right,
            ),
          );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(InkWell, 'Покормила'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сейчас'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Прошлое кормление — Правая'), findsOneWidget);
    });
  });
}
