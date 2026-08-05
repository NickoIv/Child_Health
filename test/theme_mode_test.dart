import 'package:child_health_tracker/core/theme/theme_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

DateTime _at(int hour) => DateTime(2026, 7, 25, hour, 30);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('the choice survives a restart', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('picking a theme writes it down', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themePreferenceProvider.notifier).set(
        ThemePreference.light,
      );

      expect(container.read(themePreferenceProvider), ThemePreference.light);
      // The next launch reads this before the first frame. Without it a parent
      // who chose light got dark back on every reload, because the default is
      // automatic and most reloads happen in the evening.
      expect(await readSavedTheme(), ThemePreference.light);
    });

    test('nothing saved yet means automatic', () async {
      expect(await readSavedTheme(), ThemePreference.auto);
    });

    test('a value written by an older version is ignored, not fatal', () async {
      SharedPreferences.setMockInitialValues({'app_theme': 'sepia'});
      expect(await readSavedTheme(), ThemePreference.auto);
    });

    test('the saved choice is what the app starts on', () async {
      SharedPreferences.setMockInitialValues({'app_theme': 'light'});
      final saved = await readSavedTheme();

      final container = ProviderContainer(
        overrides: [
          themePreferenceProvider.overrideWith(() => ThemeChoice(saved)),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(themePreferenceProvider), ThemePreference.light);
    });
  });
}
