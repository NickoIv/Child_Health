import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/features/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Covers the paths where a parent changes something that already exists —
/// a diary entry, a child profile, their own account — rather than adding to
/// an empty list. These are the screens where a bug quietly destroys data
/// instead of merely failing to create it.
void main() {
  setUpAll(() => initializeDateFormatting());

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: ChildHealthApp()));
    await tester.pumpAndSettle();
  }

  Future<void> openTab(WidgetTester tester, IconData icon) async {
    await tester.tap(find.byIcon(icon).first);
    await tester.pumpAndSettle();
  }

  /// The timeline row is the tap target now — the pencil is gone, because an
  /// entry you can open by touching it does not need a second control saying
  /// so. IntrinsicHeight is the row's own wrapper, so the first one is the
  /// first entry.
  Future<void> openFirstEntry(WidgetTester tester) async {
    await tester.tap(find.byType(IntrinsicHeight).first);
    await tester.pumpAndSettle();
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.account_circle_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Профиль и настройки'));
    await tester.pumpAndSettle();
  }

  group('measurements from the growth tab', () {
    testWidgets('the tab offers a button to add one', (tester) async {
      await pumpApp(tester);
      await openTab(tester, Icons.show_chart_outlined);

      expect(
        find.widgetWithText(FloatingActionButton, 'Добавить измерение'),
        findsOneWidget,
      );
    });

    testWidgets('the button opens the form already set to a measurement', (
      tester,
    ) async {
      await pumpApp(tester);
      await openTab(tester, Icons.show_chart_outlined);

      await tester.tap(find.text('Добавить измерение'));
      await tester.pumpAndSettle();

      // Weight and height fields only appear once the entry type is
      // "measurement" — their presence is what proves the type was preset.
      expect(find.textContaining('Вес'), findsWidgets);
      expect(find.textContaining('Рост'), findsWidgets);
    });
  });

  group('editing a diary entry', () {
    testWidgets('tapping a row opens the entry with its text in place', (
      tester,
    ) async {
      await pumpApp(tester);
      await openTab(tester, Icons.auto_stories_outlined);

      expect(find.text('Первое слово'), findsWidgets);

      await openFirstEntry(tester);

      expect(find.widgetWithText(AlertDialog, 'Изменить запись'), findsOneWidget);
      // Prefilled, not blank: an edit that starts empty is a delete with
      // extra steps.
      expect(
        find.byWidgetPredicate(
          (w) => w is TextFormField && w.controller?.text.isNotEmpty == true,
        ),
        findsWidgets,
      );
    });

    testWidgets('saving replaces the entry instead of adding a second one', (
      tester,
    ) async {
      await pumpApp(tester);
      await openTab(tester, Icons.auto_stories_outlined);

      await openFirstEntry(tester);

      // Whichever entry the feed put first — read its title back out of the
      // form so the assertion does not depend on the seed order.
      final title = find.byType(TextFormField).first;
      final original = tester.widget<TextFormField>(title).controller!.text;
      expect(original, isNotEmpty);

      await tester.tap(find.widgetWithText(TextButton, 'Отмена'));
      await tester.pumpAndSettle();
      // The seed repeats some titles, so count rather than assume one.
      final before = find.text(original).evaluate().length;

      await openFirstEntry(tester);
      await tester.enterText(
        find.byType(TextFormField).first,
        '$original (уточнено)',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
      await tester.pumpAndSettle();

      expect(find.text('$original (уточнено)'), findsOneWidget);
      // One fewer, not the same count plus a copy: an edit that silently
      // forks the entry is worse than no edit at all.
      expect(find.text(original).evaluate().length, before - 1);
    });
  });

  group('home screen customisation', () {
    testWidgets('no longer sits on the home screen itself', (tester) async {
      await pumpApp(tester);

      // The button used to live here, one tap from a screen opened dozens of
      // times a day for something done twice a year.
      expect(find.text('Настроить'), findsNothing);
    });

    testWidgets('lives in settings', (tester) async {
      await pumpApp(tester);
      await openSettings(tester);

      expect(find.byType(DashboardLayoutEditor), findsOneWidget);
      expect(find.text('Блоки на главном экране'), findsOneWidget);
    });
  });

  group('account editing', () {
    testWidgets('settings offers a password change and a deletion', (
      tester,
    ) async {
      await pumpApp(tester);
      await openSettings(tester);

      expect(find.text('Сменить пароль'), findsOneWidget);
      expect(find.text('Удалить учётную запись'), findsOneWidget);
    });

    testWidgets('the password dialog refuses a mismatched repeat', (
      tester,
    ) async {
      await pumpApp(tester);
      await openSettings(tester);

      await tester.tap(find.text('Сменить пароль'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'old-password');
      await tester.enterText(fields.at(1), 'new-password');
      await tester.enterText(fields.at(2), 'new-passwrod');
      await tester.tap(find.widgetWithText(FilledButton, 'Сменить'));
      await tester.pumpAndSettle();

      expect(find.text('Пароли не совпадают'), findsOneWidget);
      // Still open: a typo must not close the dialog and report success.
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('deletion stays disabled until the word is typed', (
      tester,
    ) async {
      await pumpApp(tester);
      await openSettings(tester);

      // Last section of a page that keeps growing. ensureVisible, not
      // scrollUntilVisible: the list builds its lower cards before they are on
      // screen, so the finder is satisfied while the button is still below the
      // fold and the tap lands on nothing.
      await tester.ensureVisible(find.text('Удалить учётную запись'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удалить учётную запись'));
      await tester.pumpAndSettle();

      final confirm = find.widgetWithText(FilledButton, 'Удалить навсегда');
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

      // Scoped to the dialog: the settings screen behind it has a text field
      // of its own, and an unscoped finder picks that one up first.
      final fields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.at(0), 'my-password');
      await tester.pump();
      // Password alone is not enough — this is the one action with no undo.
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

      await tester.enterText(fields.at(1), 'УДАЛИТЬ');
      await tester.pump();
      expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    });
  });

  group('child profile', () {
    testWidgets('the new-profile form offers a photo', (tester) async {
      await pumpApp(tester);
      await openTab(tester, Icons.family_restroom_outlined);

      await tester.tap(find.text('Добавить ребёнка'));
      await tester.pumpAndSettle();

      expect(find.text('Добавить фото'), findsOneWidget);
      expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);
    });

    testWidgets('an existing profile can be edited', (tester) async {
      await pumpApp(tester);
      await openTab(tester, Icons.family_restroom_outlined);

      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();

      expect(find.text('Профиль ребёнка'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'Тимур');
      await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
      await tester.pumpAndSettle();

      expect(find.text('Тимур'), findsWidgets);
      expect(find.text('Демо-профиль'), findsNothing);
    });
  });
}
