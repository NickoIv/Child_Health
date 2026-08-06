import 'package:child_health_tracker/core/theme/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Motion, and the restraint it is held to.
///
/// The rule this suite exists to keep is not "does it animate" but "does it
/// stop": an interface that moves while nobody is touching it keeps a phone's
/// GPU awake all night for the benefit of no one, on a screen that is opened
/// at three in the morning.
void main() {
  group('the durations', () {
    test('are three, and ordered', () {
      expect(Motion.quick, lessThan(Motion.normal));
      expect(Motion.normal, lessThan(Motion.slow));
      // Nothing here is long enough to be waited for.
      expect(Motion.slow.inMilliseconds, lessThan(1000));
      expect(Motion.curve, Curves.easeOutCubic);
    });
  });

  group('a counted number', () {
    testWidgets('arrives at its value and stops there', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CountUp(
            value: 12,
            builder: (context, shown) => Text('$shown'),
          ),
        ),
      );

      // Starts from nothing, so the movement is the story of the day rather
      // than a flicker between two numbers.
      expect(find.text('0'), findsOneWidget);

      await tester.pump(Motion.slow ~/ 2);
      final midway = int.parse(
        (tester.widget<Text>(find.byType(Text)).data)!,
      );
      expect(midway, greaterThan(0));
      expect(midway, lessThan(12));

      await tester.pumpAndSettle();
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('settles, so nothing is left running', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CountUp(value: 4, builder: (context, v) => Text('$v')),
        ),
      );
      // pumpAndSettle returns only when no frame is scheduled — it would
      // time out on anything that repeats.
      await tester.pumpAndSettle();
      expect(find.text('4'), findsOneWidget);
    });
  });

  group('a skeleton', () {
    testWidgets('keeps the size of what it stands in for', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(child: Skeleton(width: 120, height: 14)),
        ),
      );
      await tester.pump();

      expect(tester.getSize(find.byType(Skeleton)), const Size(120, 14));
    });

    testWidgets('breathes rather than sits still', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Center(child: Skeleton(width: 100, height: 10))),
      );

      Color colourNow() {
        final box = tester.widget<Container>(
          find.descendant(
            of: find.byType(Skeleton),
            matching: find.byType(Container),
          ),
        );
        return (box.decoration! as BoxDecoration).color!;
      }

      await tester.pump();
      final first = colourNow();
      await tester.pump(const Duration(milliseconds: 350));
      expect(colourNow(), isNot(first));

      // Faint at its strongest: this is a sign of life, not a thing to look
      // at while waiting.
      expect(colourNow().a, lessThan(0.12));
    });
  });

  group('switching tabs', () {
    testWidgets('replaces one screen with another', (tester) async {
      Widget app(int index, String label) => MaterialApp(
        home: TabSwitch(index: index, child: Text(label)),
      );

      await tester.pumpWidget(app(0, 'home'));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);

      await tester.pumpWidget(app(1, 'diary'));
      await tester.pumpAndSettle();

      // The old screen is gone rather than stacked behind the new one: two
      // scrollables in one place show through each other.
      expect(find.text('home'), findsNothing);
      expect(find.text('diary'), findsOneWidget);
    });

    testWidgets('does not animate a screen that has not changed', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: TabSwitch(index: 0, child: Text('home'))),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        const MaterialApp(home: TabSwitch(index: 0, child: Text('home'))),
      );
      // Settles immediately: a rebuild of the same tab is not a transition.
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(find.text('home'), findsOneWidget);
    });
  });
}
