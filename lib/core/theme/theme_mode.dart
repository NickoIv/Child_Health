import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class ThemeChoice extends Notifier<ThemePreference> {
  @override
  ThemePreference build() => ThemePreference.auto;

  void set(ThemePreference value) => state = value;
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
