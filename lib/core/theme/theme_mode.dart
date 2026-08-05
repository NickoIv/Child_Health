import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How the app decides between light and dark.
enum ThemePreference {
  auto('Автоматически', 'Тёмная с 21:00 до 7:00'),
  light('Светлая', ''),
  dark('Тёмная', '');

  const ThemePreference(this.label, this.hint);

  final String label;
  final String hint;
}

/// Hour at which the app switches to dark, and back.
///
/// Night feeds are a large share of when this app is opened, and a white
/// screen at 3am wakes both the parent and the baby. Following the system
/// setting is not enough: phones are usually left on light, and a parent
/// holding a child is not going to go change it.
const nightStartHour = 21;
const nightEndHour = 7;

bool isNightAt(DateTime moment) =>
    moment.hour >= nightStartHour || moment.hour < nightEndHour;

const _storageKey = 'app_theme';

/// What the app opens on before anyone has chosen.
///
/// Light, not automatic. The warm palette *is* the app — it is what makes a
/// record of a hard week feel like something other than paperwork — and
/// automatic meant a parent who only ever opens this thing after the evening
/// feed never once saw it. Dim-at-night is still a switch away, and now that
/// the choice is remembered it is a switch flipped once.
const defaultTheme = ThemePreference.light;

ThemePreference themeForName(String? name) => ThemePreference.values.firstWhere(
  (t) => t.name == name,
  orElse: () => defaultTheme,
);

/// Reads the saved appearance, for `main.dart` to seed the provider with
/// before the first frame.
///
/// Without this a parent who chose the light theme got the dark one back on
/// every reload, because the default is automatic and most of the reloads
/// happen at night.
Future<ThemePreference> readSavedTheme() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return themeForName(prefs.getString(_storageKey));
  } catch (_) {
    // No preferences plugin on this platform, or storage refused.
    return defaultTheme;
  }
}

class ThemeChoice extends Notifier<ThemePreference> {
  ThemeChoice([this._initial = defaultTheme]);

  final ThemePreference _initial;

  @override
  ThemePreference build() => _initial;

  Future<void> set(ThemePreference value) async {
    // Applied first: the screen should change under the finger, not after the
    // write to disk comes back.
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, value.name);
    } catch (_) {
      // Kept for this run even if it could not be stored.
    }
  }
}

final themePreferenceProvider =
    NotifierProvider<ThemeChoice, ThemePreference>(ThemeChoice.new);

/// Resolved mode for MaterialApp.
///
/// [now] is injectable so the switching logic can be tested without waiting
/// for nightfall.
ThemeMode resolveThemeMode(ThemePreference preference, {DateTime? now}) {
  return switch (preference) {
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
    ThemePreference.auto => isNightAt(now ?? DateTime.now())
        ? ThemeMode.dark
        : ThemeMode.light,
  };
}

final themeModeProvider = Provider<ThemeMode>((ref) {
  return resolveThemeMode(ref.watch(themePreferenceProvider));
});
