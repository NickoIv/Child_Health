import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(initializeDateFormatting);

  Future<void> pumpIn(WidgetTester tester, Locale? locale) async {
    tester.view.physicalSize = const Size(1400, 2400);
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

  // The demo stack is always signed in, so what these land on is the shell:
  // its title and its navigation, which is where a wrong language would be
  // most obvious.
  testWidgets('Russian is what an untouched install shows', (tester) async {
    await pumpIn(tester, null);

    expect(find.text('Обзор'), findsWidgets);
    expect(find.text('Дневник'), findsWidgets);
  });

  testWidgets('English relabels the whole navigation', (tester) async {
    await pumpIn(tester, const Locale('en'));

    expect(find.text('Overview'), findsWidgets);
    expect(find.text('Diary'), findsWidgets);
    expect(find.text('Обзор'), findsNothing);
  });

  testWidgets('Kazakh relabels the whole navigation', (tester) async {
    await pumpIn(tester, const Locale('kk'));

    expect(find.text('Шолу'), findsWidgets);
    expect(find.text('Күнделік'), findsWidgets);
    expect(find.text('Обзор'), findsNothing);
  });

  group('every locale is complete', () {
    for (final locale in supportedLocales) {
      test('${locale.languageCode} has no empty strings', () async {
        final l = await AppLocalizations.delegate.load(locale);

        // A sample across the areas that were translated, rather than every
        // getter: a gap shows up as an empty string, not as a missing key.
        for (final value in [
          l.appTitle,
          l.navDashboard,
          l.authSignIn,
          l.authErrorInvalidCredentials,
          l.settingsLanguage,
          l.notificationChannelName,
          l.reminderTypeVaccination,
          l.deleteAccountConfirm,
        ]) {
          expect(value.trim(), isNotEmpty);
        }
      });
    }
  });

  test('an unsupported language code falls back to Russian', () {
    expect(localeForCode('de'), defaultLocale);
    expect(localeForCode(null), defaultLocale);
    expect(localeForCode('kk'), const Locale('kk'));
  });
}
