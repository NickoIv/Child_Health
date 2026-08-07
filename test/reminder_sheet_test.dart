import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/features/reminders/reminder_sheet.dart';
import 'package:child_health_tracker/features/shared/widgets.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Setting a reminder.
///
/// The planner shipped able to show reminders and unable to make one: the
/// vaccination calendar generated its own, and everything else — a dose in
/// four hours, a clinic visit on Thursday — had no way in. These tests are
/// about the way in, and about it being short: a mother holding a child is
/// not going to walk a wizard.
void main() {
  setUpAll(() => initializeDateFormatting());

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: ChildHealthApp()));
    await tester.pumpAndSettle();
  }

  Future<AppLocalizations> openSheet(WidgetTester tester) async {
    final l = await AppLocalizations.delegate.load(const Locale('ru'));
    await tester.tap(find.text(l.reminderAdd).first);
    await tester.pumpAndSettle();
    return l;
  }

  /// The name field on the sheet, not whichever TextField the screen behind
  /// it happens to own.
  Finder nameField() => find.byKey(reminderNameFieldKey);

  /// Opens the planner, which is where a saved reminder has to show up. The
  /// assertion is made on screen rather than in the repository: what the
  /// sheet is for is the row a parent sees afterwards.
  Future<void> openPlanner(WidgetTester tester, AppLocalizations l) async {
    await tester.tap(find.text(l.navReminders).last);
    await tester.pumpAndSettle();
  }

  testWidgets('the way in is on the home screen, not three taps away', (
    tester,
  ) async {
    await pumpApp(tester);
    final l = await openSheet(tester);

    // Behind «Ещё» → «Напоминания» → a button, it may as well not exist. On
    // the home screen it is one tap from the four she already uses.
    expect(find.text(l.reminderNew), findsOneWidget);
  });

  testWidgets('it opens on a medicine, a few hours from now, once', (
    tester,
  ) async {
    await pumpApp(tester);
    final l = await openSheet(tester);

    // The default is the case a newborn actually generates. Nothing has to be
    // chosen for it — only the name typed and the button pressed.
    expect(find.text(l.reminderTypeMedication), findsWidgets);
    expect(find.text(l.reminderInHours(4)), findsOneWidget);
    expect(find.text(l.recurrenceNone), findsOneWidget);
  });

  testWidgets('a vaccination is not a type anyone types by hand', (
    tester,
  ) async {
    await pumpApp(tester);
    final l = await openSheet(tester);

    // Those come from the national calendar with the right dates on them, and
    // a hand-typed duplicate beside a generated one is worse than nothing.
    expect(find.text(l.reminderTypeVaccination), findsNothing);
  });

  testWidgets('a reminder without a name is refused, not saved empty', (
    tester,
  ) async {
    await pumpApp(tester);
    final l = await openSheet(tester);

    await tester.tap(find.widgetWithText(FilledButton, l.commonSave));
    await tester.pumpAndSettle();

    expect(find.text(l.reminderNameRequired), findsOneWidget);
    // Still open: a sheet that closes on a mistake loses what was typed.
    expect(find.text(l.reminderNew), findsOneWidget);
  });

  testWidgets('typing a dose and saving writes it down and says when', (
    tester,
  ) async {
    await pumpApp(tester);
    final l = await openSheet(tester);

    await tester.enterText(nameField(), 'Нурофен, 2,5 мл');
    await tester.tap(find.text(l.reminderInHours(6)));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l.commonSave));
    await tester.pumpAndSettle();

    // The confirmation says the time back, because the whole point of the
    // hour chips is that she never read a date.
    expect(find.textContaining('Напомню'), findsOneWidget);

    // And it is in the planner, under medication rather than under the
    // vaccination calendar it has nothing to do with.
    await openPlanner(tester, l);
    expect(find.text('Нурофен, 2,5 мл'), findsWidgets);
    expect(
      find.ancestor(
        of: find.text('Нурофен, 2,5 мл'),
        matching: find.widgetWithText(SectionCard, l.remindersMedications),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a repeating dose keeps its recurrence', (tester) async {
    await pumpApp(tester);
    final l = await openSheet(tester);

    await tester.enterText(nameField(), 'Витамин D');
    await tester.tap(find.text(l.recurrenceDaily));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l.commonSave));
    await tester.pumpAndSettle();

    // A vitamin is a daily dose, and the row says so — otherwise a repeat is
    // a setting a parent chose once and can never see again.
    await openPlanner(tester, l);
    // Widgets rather than one: the confirmation strip is still on screen and
    // it names the reminder too.
    expect(find.text('Витамин D'), findsWidgets);
    expect(find.text(l.recurrenceDaily), findsWidgets);
  });

  testWidgets('the planner offers the same sheet from its own button', (
    tester,
  ) async {
    await pumpApp(tester);
    final l = await AppLocalizations.delegate.load(const Locale('ru'));

    // Both entry points must open the same form; two ways in that ask
    // different questions is how a planner ends up with two kinds of entry.
    await openPlanner(tester, l);

    await tester.tap(find.widgetWithText(FloatingActionButton, l.reminderAdd));
    await tester.pumpAndSettle();

    expect(find.text(l.reminderNew), findsOneWidget);
    expect(find.text(l.reminderWhen.toUpperCase()), findsOneWidget);
  });
}
