import 'dart:io';

import 'package:child_health_tracker/core/app_info.dart';
import 'package:child_health_tracker/core/theme/app_snack.dart';
import 'package:child_health_tracker/core/theme/app_theme.dart';
import 'package:child_health_tracker/core/theme/motion.dart';
import 'package:child_health_tracker/features/shared/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the second pass over the look was actually asked for.
///
/// Three visible things — the card has an edge, a confirmation is noticed, a
/// tab answers the finger — and one invisible one: the author's name is in the
/// app rather than only in a readme.
void main() {
  group('the card has an edge', () {
    test('page and card are no longer the same cream', () {
      // The whole complaint about the previous passes was that nothing
      // changed on screen. This is the reason: page and card differed by
      // three points of lightness, so no card had a visible boundary.
      double lightness(Color c) => HSLColor.fromColor(c).lightness;
      expect(
        lightness(Warm.primaryCard) - lightness(Warm.background),
        greaterThan(0.02),
      );
      expect(Warm.primaryCard, const Color(0xFFFFFFFF));
    });

    test('the dark theme keeps the same relationship, inverted', () {
      double lightness(Color c) => HSLColor.fromColor(c).lightness;
      final page = AppTheme.dark().scaffoldBackgroundColor;
      expect(
        lightness(Warm.card(Brightness.dark)) - lightness(page),
        greaterThan(0.01),
      );
    });

    test('a hairline separates rows without ruling them apart', () {
      for (final mode in Brightness.values) {
        expect(Warm.hairline(mode).a, lessThan(0.15), reason: mode.name);
      }
    });
  });

  group('a figure is bigger than its label', () {
    test('the caps label is below every reading size', () {
      expect(AppTheme.microSize, lessThan(AppTheme.secondarySize));
      final label = AppTheme.microLabel(Brightness.light);
      expect(label.fontWeight, FontWeight.w800);
      expect(label.letterSpacing, greaterThan(1));
    });

    test('numbers that sit in a column line up', () {
      // Times down the recent list, weights down the history: proportional
      // digits make a column of them wobble by a couple of pixels a row.
      final text = AppTheme.light().textTheme;
      expect(text.labelSmall?.fontFeatures, AppTheme.tabular);
      expect(text.labelMedium?.fontFeatures, AppTheme.tabular);
    });

    testWidgets('a block label is printed in caps on the page', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: SectionLabel(text: 'Последние события')),
        ),
      );

      expect(find.text('ПОСЛЕДНИЕ СОБЫТИЯ'), findsOneWidget);
    });
  });

  group('a confirmation is noticed', () {
    test('the strip is the one dark surface in the light theme', () {
      final snack = AppTheme.light().snackBarTheme;
      expect(snack.behavior, SnackBarBehavior.floating);
      expect(snack.backgroundColor!.computeLuminance(), lessThan(0.05));
      expect(snack.contentTextStyle!.color!.computeLuminance(), greaterThan(0.8));
    });

    test('three kinds, and none of them is an alert', () {
      // An alert in this app is a red screen with a phone number on it. A
      // strip that slides away in a few seconds must never be mistaken for
      // one, so nothing here is allowed the alert red.
      for (final kind in SnackKind.values) {
        expect(kind.tint, isNot(StatusColors.alert));
        // Long enough to read at a glance, short enough not to sit over the
        // screen — «три секунды и пусть исчезает».
        expect(kind.duration.inSeconds, greaterThanOrEqualTo(3));
        expect(kind.duration.inSeconds, lessThanOrEqualTo(5));
      }
      // A problem stays longest: it is read twice by someone holding a child.
      expect(
        SnackKind.problem.duration,
        greaterThan(SnackKind.done.duration),
      );
    });

    testWidgets('a saved entry gets the tick, not a second animation', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  appSnack('Записано', kind: SnackKind.done),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pump();

      expect(find.text('Записано'), findsOneWidget);
      expect(find.byType(SuccessCheck), findsOneWidget);
    });
  });

  group('a tab answers the finger', () {
    test('the icon lifts and swells, and settles rather than bounces', () {
      expect(NavIcon.grownScale, greaterThan(1));
      // Small enough to be felt rather than watched: past 1.2 the glyph
      // collides with the edge of the pill behind it.
      expect(NavIcon.grownScale, lessThan(1.2));
      expect(NavIcon.lift, lessThanOrEqualTo(4));
      expect(NavIcon.duration.inMilliseconds, lessThan(300));
    });

    testWidgets('it is at rest when its tab is not the one open', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: NavIcon(icon: Icons.home_outlined, selected: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scale = tester.widget<Transform>(
        find.byType(Transform).last,
      );
      expect(scale.transform.getMaxScaleOnAxis(), closeTo(1, 0.001));
    });
  });

  group('the author', () {
    test('is in the app, not only in the readme', () {
      expect(AppInfo.author, 'Ивашикин Николай');
    });

    test('and the version matches the pubspec it was built from', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('version: ${AppInfo.version}'));
      expect(pubspec, contains(AppInfo.author));
    });
  });
}
