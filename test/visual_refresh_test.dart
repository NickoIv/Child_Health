import 'dart:math' as math;

import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/features/dashboard/focus_home.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/core/theme/app_theme.dart';
import 'package:child_health_tracker/core/theme/motion.dart';
import 'package:child_health_tracker/features/dashboard/now_card.dart';
import 'package:child_health_tracker/features/shared/photo_widgets.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// The refresh was a promise about how the app feels, and feelings are the one
/// thing a test cannot check. What it can check is everything the feeling was
/// built out of: that the pastels stay readable, that the type scale stayed
/// four sizes and not seven, that the six actions are six different colours,
/// and that nothing warm crept into the places where colour means something.
void main() {
  setUpAll(initializeDateFormatting);

  /// WCAG relative luminance.
  double luminance(Color c) {
    double channel(double v) =>
        v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4) as double;
    return 0.2126 * channel(c.r) +
        0.7152 * channel(c.g) +
        0.0722 * channel(c.b);
  }

  double contrast(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    final hi = math.max(la, lb);
    final lo = math.min(la, lb);
    return (hi + 0.05) / (lo + 0.05);
  }

  group('the soft palette', () {
    // The whole point of a pastel is that it is nearly the background, which
    // is also the whole way a pastel palette goes unreadable. Every pair is
    // held at the text minimum in both modes.
    for (final tone in SoftTone.values) {
      for (final mode in Brightness.values) {
        test('${tone.name} is readable in ${mode.name}', () {
          expect(
            contrast(tone.ink(mode), tone.fill(mode)),
            greaterThanOrEqualTo(4.5),
            reason: '${tone.name} ink on its own fill',
          );
        });
      }
    }

    test('six tones, six fills, in both modes', () {
      for (final mode in Brightness.values) {
        final fills = SoftTone.values.map((t) => t.fill(mode)).toSet();
        expect(fills.length, SoftTone.values.length);
      }
    });

    test('nothing in it is saturated', () {
      // A pastel is defined by where it sits, not by its name. In light mode
      // every fill is near-white; in dark mode near-black. If someone drops a
      // vivid hue in here it fails, because a saturated fill beside the alert
      // colour is exactly what the theme exists to prevent.
      // Measured as chroma rather than HSL saturation: a near-white with a
      // hint of peach in it scores 0.88 saturated, which says nothing. The
      // spread between the channels is what the eye actually reads as vivid.
      double chroma(Color c) =>
          [c.r, c.g, c.b].reduce(math.max) - [c.r, c.g, c.b].reduce(math.min);

      for (final tone in SoftTone.values) {
        final light = tone.fill(Brightness.light);
        expect(
          HSLColor.fromColor(light).lightness,
          greaterThan(0.88),
          reason: tone.name,
        );
        expect(chroma(light), lessThan(0.2), reason: tone.name);

        final dark = tone.fill(Brightness.dark);
        expect(
          HSLColor.fromColor(dark).lightness,
          lessThan(0.20),
          reason: tone.name,
        );
        expect(chroma(dark), lessThan(0.15), reason: tone.name);
      }
    });

    test('no soft fill impersonates a status colour', () {
      const status = [
        StatusColors.normal,
        StatusColors.warning,
        StatusColors.serious,
        StatusColors.alert,
      ];
      for (final tone in SoftTone.values) {
        for (final mode in Brightness.values) {
          expect(status, isNot(contains(tone.fill(mode))));
          expect(status, isNot(contains(tone.ink(mode))));
        }
      }
    });
  });

  group('the warm greeting', () {
    test('is pastel, not the old saturated ramp', () {
      final light = AppTheme.welcomeGradient(Brightness.light);
      for (final c in light.colors) {
        expect(luminance(c), greaterThan(0.7));
      }

      final dark = AppTheme.welcomeGradient(Brightness.dark);
      for (final c in dark.colors) {
        expect(luminance(c), lessThan(0.1));
      }
    });

    test('carries readable text at both ends of the gradient', () {
      // White on peach is the single easiest way to make a soft palette look
      // broken, so the ink is checked against both stops rather than one.
      for (final mode in Brightness.values) {
        for (final stop in AppTheme.welcomeGradient(mode).colors) {
          expect(
            contrast(AppTheme.onWelcome(mode), stop),
            greaterThanOrEqualTo(4.5),
            reason: mode.name,
          );
        }
      }
    });
  });

  group('the type scale', () {
    test('is four sizes and stays four sizes', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final t = theme.textTheme;
        expect(t.headlineSmall?.fontSize, AppTheme.headerSize);
        expect(t.titleLarge?.fontSize, AppTheme.sectionSize);
        expect(t.bodyMedium?.fontSize, AppTheme.bodySize);
        expect(t.bodyLarge?.fontSize, AppTheme.bodySize);
        expect(t.bodySmall?.fontSize, AppTheme.secondarySize);
      }
    });

    test('the header is the largest thing and the caption the smallest', () {
      expect(AppTheme.headerSize, greaterThan(AppTheme.sectionSize));
      expect(AppTheme.sectionSize, greaterThan(AppTheme.bodySize));
      expect(AppTheme.bodySize, greaterThan(AppTheme.secondarySize));
    });
  });

  group('the phrase of the day', () {
    test('changes once a night and not once a rebuild', () {
      final morning = DateTime(2026, 8, 5, 6);
      final night = DateTime(2026, 8, 5, 23, 59);
      expect(phraseOfDayIndex(morning, 6), phraseOfDayIndex(night, 6));

      final tomorrow = DateTime(2026, 8, 6, 6);
      expect(
        phraseOfDayIndex(tomorrow, 6),
        isNot(phraseOfDayIndex(morning, 6)),
      );
    });

    test('walks all six before it repeats', () {
      final seen = {
        for (var d = 0; d < 6; d++)
          phraseOfDayIndex(DateTime(2026, 8, 5).add(Duration(days: d)), 6),
      };
      expect(seen.length, 6);
    });

    test('all six exist in all three languages, and none of them diagnoses',
        () async {
      // These are the only sentences in the app that speak to the mother
      // about herself. A phrase that told her something about the child would
      // be a medical opinion with a flower next to it.
      const forbidden = [
        'норм',
        'должн',
        'диагноз',
        'болезн',
        'symptom',
        'should',
        'normal',
        'diagnos',
      ];

      for (final locale in supportedLocales) {
        final l = await AppLocalizations.delegate.load(locale);
        final phrases = phrasesOfDay(l);

        expect(phrases.length, 6);
        expect(phrases.toSet().length, 6, reason: locale.languageCode);
        for (final phrase in phrases) {
          expect(phrase.trim(), isNotEmpty, reason: locale.languageCode);
          for (final word in forbidden) {
            expect(
              phrase.toLowerCase().contains(word),
              isFalse,
              reason: '«$word» in ${locale.languageCode}: $phrase',
            );
          }
        }
      }
    });
  });

  group('motion stays out of the way', () {
    test('a press dips, it does not jump', () {
      expect(Pressable.pressedScale, 0.97);
      expect(Pressable.duration.inMilliseconds, lessThan(200));
    });

    test('the success tick is the 800ms it was asked to be', () {
      expect(SuccessCheck.duration.inMilliseconds, 800);
    });

    test('an arrival is quick enough not to be waited on', () {
      expect(Arrival.duration.inMilliseconds, lessThan(400));
      expect(Arrival.rise, lessThanOrEqualTo(12));
    });
  });

  group('on the screen', () {
    Future<void> pump(
      WidgetTester tester, {
      Locale? locale,
      Size size = const Size(390, 844),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            if (locale != null)
              localeProvider.overrideWith(() => LocaleChoice(locale)),
          ],
          child: const ChildHealthApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the greeting leads with the child, big', (tester) async {
      await pump(tester);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      // The avatar is the size a face has to be to be recognised rather than
      // acknowledged. Smaller than it was: the header lost the four facts
      // that used to sit beside it, so it no longer needs their height.
      final avatar = tester.widget<ChildAvatar>(find.byType(ChildAvatar).first);
      expect(avatar.size, greaterThanOrEqualTo(56));
      expect(avatar.size, lessThanOrEqualTo(96));

      // The name is the header size, not a card title.
      final name = tester.widget<Text>(find.text('Демо-профиль').first);
      expect(name.style?.fontSize, AppTheme.headerSize);

      // The phrase of the day went with the block it belonged to; on the
      // home screen it is a sentence between a thumb and a feed.
      expect(
        phrasesOfDay(l).where((p) => find.text(p).evaluate().isNotEmpty),
        isEmpty,
      );
    });

    testWidgets('the four quick actions are four different pastels', (
      tester,
    ) async {
      await pump(tester);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      final fills = <Color>{};
      for (final label in [
        l.quickFeed,
        l.quickSleep,
        l.quickNappy,
        l.quickTemperature,
      ]) {
        final card = find.ancestor(
          of: find.text(label),
          matching: find.byType(Container),
        );
        final decoration =
            tester.widget<Container>(card.first).decoration! as BoxDecoration;
        fills.add(decoration.color!);

        // Every one of them is a pastel from the set, not a one-off. Asked
        // for the brightness actually on screen: after nine in the evening
        // the app is dark, and the dark pair is the right answer there.
        final brightness = Theme.of(
          tester.element(find.byType(ActionCard).first),
        ).brightness;
        expect(
          SoftTone.values.map((t) => t.fill(brightness)),
          contains(decoration.color),
          reason: label,
        );
      }
      expect(fills.length, 4, reason: 'four actions, four tones');
    });

    testWidgets('every quick action card is the same 112px card', (
      tester,
    ) async {
      // Kazakh has the longest labels of the three, so if the grid is going
      // to go ragged it goes ragged here.
      await pump(tester, locale: const Locale('kk'));
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

      for (final size in sizes) {
        expect(size.height, 112);
        expect(size.width, closeTo(sizes.first.width, 0.5));
      }
    });

    testWidgets('a caption sits under every quick action', (tester) async {
      await pump(tester);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      for (final caption in [
        l.quickFeedHint,
        l.quickSleepHint,
        l.quickNappyHint,
        l.quickTemperatureHint,
      ]) {
        expect(find.text(caption), findsOneWidget, reason: caption);
      }
    });

    testWidgets('the timeline gives every event its own surface', (
      tester,
    ) async {
      await pump(tester, size: const Size(900, 1400));

      await tester.tap(find.byIcon(Icons.auto_stories_outlined).first);
      await tester.pumpAndSettle();

      // Each entry arrives rather than appearing, and each one is pressable
      // in its own right — the row is the tap target, not the card behind it.
      expect(find.byType(Arrival), findsWidgets);
      expect(find.byType(Pressable), findsWidgets);
    });
  });
}
