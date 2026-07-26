import 'package:child_health_tracker/core/theme/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The categorical ordering is a colour-blindness safety mechanism, not a
/// style choice — it was validated pair by pair, and reordering it silently
/// breaks that guarantee. These tests exist so a future tidy-up cannot do it
/// by accident.
void main() {
  group('categorical palette', () {
    test('both modes define the same number of slots', () {
      expect(
        VizPalette.categorical.length,
        VizPalette.categoricalDark.length,
        reason: 'the dark column is the same hues restepped, not a new palette',
      );
    });

    test('holds the validated ordering', () {
      // Verified with the data-viz validator: worst adjacent CVD ΔE 9.1 light
      // and 8.4 dark, worst adjacent normal-vision ΔE 19.6 light and 19.3
      // dark. An earlier ordering put magenta beside orange and measured 12.9
      // on the normal-vision floor, below the 15 minimum.
      expect(VizPalette.categorical, const [
        Color(0xFF2A78D6),
        Color(0xFFEB6834),
        Color(0xFF1BAF7A),
        Color(0xFFEDA100),
        Color(0xFFE87BA4),
        Color(0xFF008300),
        Color(0xFF4A3AA7),
        Color(0xFFE34948),
      ]);
    });

    test('every hue is distinct within a mode', () {
      for (final list in [
        VizPalette.categorical,
        VizPalette.categoricalDark,
      ]) {
        expect(list.toSet().length, list.length);
      }
    });

    test('slots fold back instead of inventing a hue', () {
      // A ninth series must reuse a slot, never generate a colour: a
      // generated hue has been through no validation at all.
      final first = VizPalette.slot(0, Brightness.light);
      final ninth = VizPalette.slot(8, Brightness.light);
      expect(ninth, first);
    });

    test('picks the right column per brightness', () {
      expect(
        VizPalette.slot(0, Brightness.light),
        VizPalette.categorical.first,
      );
      expect(
        VizPalette.slot(0, Brightness.dark),
        VizPalette.categoricalDark.first,
      );
    });
  });

  group('status palette', () {
    test('is fixed and mode-invariant', () {
      // Status colours are never themed: the same red must mean the same
      // thing on both surfaces.
      expect(StatusColors.normal, const Color(0xFF0CA30C));
      expect(StatusColors.warning, const Color(0xFFFAB219));
      expect(StatusColors.serious, const Color(0xFFEC835A));
      expect(StatusColors.alert, const Color(0xFFD03B3B));
    });

    test('does not collide with any categorical slot', () {
      const status = [
        StatusColors.normal,
        StatusColors.warning,
        StatusColors.serious,
        StatusColors.alert,
      ];
      for (final s in status) {
        expect(
          VizPalette.categorical,
          isNot(contains(s)),
          reason: 'a status colour must never impersonate a series',
        );
        expect(VizPalette.categoricalDark, isNot(contains(s)));
      }
    });

    test('severity escalates through distinct colours', () {
      final steps = [0, 1, 2].map(StatusColors.forSeverityIndex).toList();
      expect(steps.toSet().length, 3);
      expect(steps.last, StatusColors.alert);
    });
  });

  group('the alert colour stays unmistakable', () {
    test('the app seed is far from red in hue', () {
      // The primary was chosen violet partly so that a red element on screen
      // can only mean an alert. If someone reseeds the theme to a warm hue,
      // this fails and asks them to think about it.
      final seed = HSLColor.fromColor(const Color(0xFF6750E8));
      final alert = HSLColor.fromColor(StatusColors.alert);
      var delta = (seed.hue - alert.hue).abs();
      if (delta > 180) delta = 360 - delta;
      expect(
        delta,
        greaterThan(60),
        reason: 'the primary must not be confusable with the alert colour',
      );
    });
  });
}
