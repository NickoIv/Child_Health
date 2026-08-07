import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/core/theme/app_theme.dart';
import 'package:child_health_tracker/features/reminders/reminder_sheet.dart';
import 'package:child_health_tracker/features/shared/widgets.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// «И СНОВА ЧЕРНЫЙ ФОН ВЫДЕЛЕННЫХ КНОПКАХ. НЕ ВИДНО ТЕКСТ.»
///
/// Twice. The first time it was called fixed on the strength of a theme that
/// specified white — but a chip flattens a state-dependent text style before
/// anything resolves it, so the white never arrived and the label stayed dark
/// on a near-black fill. Nothing in the suite looked at the two colours
/// together, which is why it shipped.
///
/// So this test does not read the theme. It measures the pair.
void main() {
  setUpAll(initializeDateFormatting);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// WCAG relative luminance, and the 4.5:1 the rest of this app is held to.
  double luminance(Color c) => c.computeLuminance();

  double contrast(Color a, Color b) {
    final high = luminance(a) > luminance(b) ? luminance(a) : luminance(b);
    final low = luminance(a) > luminance(b) ? luminance(b) : luminance(a);
    return (high + 0.05) / (low + 0.05);
  }

  group('the label can be read off the fill', () {
    for (final brightness in Brightness.values) {
      for (final selected in const [true, false]) {
        test('$brightness, selected: $selected', () {
          final fill = ChoicePill.fill(brightness, selected: selected);
          final ink = ChoicePill.ink(brightness, selected: selected);

          expect(
            contrast(fill, ink),
            greaterThanOrEqualTo(4.5),
            reason:
                'a 13px label on a pill needs 4.5:1 — '
                'fill $fill, ink $ink',
          );
        });
      }
    }
  });

  test('a selected pill does not look like an unselected one', () {
    for (final brightness in Brightness.values) {
      final on = ChoicePill.fill(brightness, selected: true);
      final off = ChoicePill.fill(brightness, selected: false);
      expect(
        contrast(on, off),
        greaterThan(2.0),
        reason: 'selected and unselected are the same rectangle in $brightness',
      );
    }
  });

  testWidgets('the reminder sheet paints its choices as pills', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: defaultLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showReminderSheet(context, childId: 'demo'),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final l = await AppLocalizations.delegate.load(defaultLocale);

    // No Material chip is left on this sheet: they were the ones that came
    // out black on black.
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byType(ChoicePill), findsWidgets);

    // «через 4 ч» is selected on open, and its text is the light ink.
    final selected = tester.widget<Text>(
      find.descendant(
        of: find.ancestor(
          of: find.text(l.reminderInHours(4)),
          matching: find.byType(ChoicePill),
        ),
        matching: find.byType(Text),
      ),
    );
    expect(selected.style!.color, ChoicePill.ink(Brightness.light,
        selected: true));
  });

  testWidgets('«Сохранить» is whole and on screen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: defaultLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showReminderSheet(context, childId: 'demo'),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final l = await AppLocalizations.delegate.load(defaultLocale);
    final save = find.widgetWithText(FilledButton, l.commonSave);
    final box = tester.getRect(save);

    // It was cut in half by the bottom of the screen on his phone. Not "mostly
    // visible": the whole button, without scrolling anything.
    expect(box.bottom, lessThanOrEqualTo(844));
    expect(box.top, greaterThanOrEqualTo(0));
    expect(box.height, greaterThan(40));
  });
}
