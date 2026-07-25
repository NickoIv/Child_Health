import 'package:child_health_tracker/core/theme/theme_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime _at(int hour) => DateTime(2026, 7, 25, hour, 30);

void main() {
  group('isNightAt', () {
    test('is night from 21:00 through 06:59', () {
      for (final hour in [21, 22, 23, 0, 3, 5, 6]) {
        expect(isNightAt(_at(hour)), isTrue, reason: '$hour:30 should be night');
      }
    });

    test('is day from 07:00 through 20:59', () {
      for (final hour in [7, 9, 12, 17, 20]) {
        expect(isNightAt(_at(hour)), isFalse, reason: '$hour:30 should be day');
      }
    });

    test('handles the boundaries exactly', () {
      expect(isNightAt(DateTime(2026, 7, 25, 20, 59)), isFalse);
      expect(isNightAt(DateTime(2026, 7, 25, 21, 0)), isTrue);
      expect(isNightAt(DateTime(2026, 7, 25, 6, 59)), isTrue);
      expect(isNightAt(DateTime(2026, 7, 25, 7, 0)), isFalse);
    });
  });

  group('resolveThemeMode', () {
    test('auto follows the clock', () {
      expect(
        resolveThemeMode(ThemePreference.auto, now: _at(23)),
        ThemeMode.dark,
      );
      expect(
        resolveThemeMode(ThemePreference.auto, now: _at(10)),
        ThemeMode.light,
      );
    });

    test('an explicit choice overrides the clock', () {
      // A parent who picked light at midnight meant it.
      expect(
        resolveThemeMode(ThemePreference.light, now: _at(2)),
        ThemeMode.light,
      );
      expect(
        resolveThemeMode(ThemePreference.dark, now: _at(12)),
        ThemeMode.dark,
      );
    });
  });
}
