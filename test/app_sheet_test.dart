import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/core/theme/app_sheet.dart';
import 'package:child_health_tracker/core/theme/app_theme.dart';
import 'package:child_health_tracker/features/reminders/reminder_sheet.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// «Новое напоминание» came up on his phone with a black band across the top of
/// it and the first line unreadable. A scroll-controlled sheet grows to
/// whatever its content asks for, and with the keyboard up that was the whole
/// viewport — which in a home-screen PWA reaches behind the iOS status bar this
/// app declares black.
///
/// Both halves of the fix are held here: the sheet respects the inset the
/// platform reports, and it stops short of the top whether or not one is
/// reported at all.
void main() {
  setUpAll(initializeDateFormatting);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const screen = Size(390, 844);

  /// A phone with a notch: 47 logical pixels of status bar the sheet has no
  /// business drawing under.
  const inset = EdgeInsets.only(top: 47, bottom: 34);

  Future<void> openSheet(WidgetTester tester) async {
    tester.view.physicalSize = screen;
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
          home: MediaQuery(
            data: const MediaQueryData(size: screen, padding: inset),
            child: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () =>
                        showReminderSheet(context, childId: 'demo'),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('the title clears the status bar', (tester) async {
    await openSheet(tester);
    final l = await AppLocalizations.delegate.load(defaultLocale);

    final title = tester.getTopLeft(find.text(l.reminderNew)).dy;
    expect(
      title,
      greaterThan(inset.top),
      reason: 'the heading is drawn under the status bar',
    );
  });

  testWidgets('the sheet never reaches the top of the screen', (tester) async {
    await openSheet(tester);

    // Whatever the browser claims the viewport is, a sheet that stops short
    // of the top cannot be covered by a band painted over it.
    // The form is taller than the cap, so the cap is what is being measured
    // here — hence the epsilon rather than a strict greater-than.
    final sheet = tester.getRect(find.byType(BottomSheet));
    expect(
      sheet.top,
      greaterThanOrEqualTo(
        screen.height * (1 - maxSheetHeightFraction) - 0.01,
      ),
    );
  });

  test('the cap leaves a visible strip of the page behind it', () {
    expect(maxSheetHeightFraction, lessThan(1.0));
    // Low enough to clear a notch on the tallest phone, high enough that the
    // reminder form is not scrolled from the first field.
    expect(maxSheetHeightFraction, inInclusiveRange(0.8, 0.9));
  });
}
