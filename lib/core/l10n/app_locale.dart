import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Russian first, and Russian when nothing has been chosen: this app was
/// written for parents in Kazakhstan, where the clinic paperwork it mirrors is
/// still mostly Russian.
const defaultLocale = Locale('ru');

const supportedLocales = [Locale('ru'), Locale('en'), Locale('kk')];

const _storageKey = 'app_locale';

Locale localeForCode(String? code) => supportedLocales.firstWhere(
  (locale) => locale.languageCode == code,
  orElse: () => defaultLocale,
);

/// Reads the saved language, for `main.dart` to seed the provider with before
/// the first frame — switching language after one has been drawn would show
/// the wrong one for an instant.
Future<Locale> readSavedLocale() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return localeForCode(prefs.getString(_storageKey));
  } catch (_) {
    // No preferences plugin on this platform, or storage refused. The default
    // is not worth crashing over.
    return defaultLocale;
  }
}

class LocaleChoice extends Notifier<Locale> {
  LocaleChoice([this._initial = defaultLocale]);

  final Locale _initial;

  @override
  Locale build() => _initial;

  Future<void> set(Locale locale) async {
    if (!supportedLocales.contains(locale)) return;
    // Applied first: the interface should change under the finger, not after
    // the write to disk comes back.
    state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, locale.languageCode);
    } catch (_) {
      // Kept for this run even if it could not be stored.
    }
  }
}

final localeProvider = NotifierProvider<LocaleChoice, Locale>(
  LocaleChoice.new,
);
