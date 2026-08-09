import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/reminder.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// A reminder that vanishes when you touch it.
///
/// He reported it in one sentence — «нажал на напоминание, и оно исчезло» —
/// and there were two ways to get there. A Checkbox carries a 48px tap area
/// however small it is drawn, and with four pixels beside it that area
/// reached under the first letters of the title; ticking one off then hid the
/// row in silence, which is indistinguishable from losing it. And in the
/// sheet, «Удалить» sat four pixels under «Сохранить» with no confirmation.
///
/// The cause turned out to be neither: the row sat in the bottom eighty
/// pixels of the screen, where the page runs under the frosted tab bar, and
/// the bar took the tap and went to «Обзор». Nothing was ever deleted. That
/// is why every test here scrolls the row clear first — a tap aimed at a
/// widget the bar covers is a test of the bar.
///
/// The two guards are still worth having, because the same sentence describes
/// a mis-tick and a mis-delete: completing says so and offers the way back,
/// and deleting asks first.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeDateFormatting);

  final child = Child(
    id: 'c1',
    parentUid: 'p1',
    name: 'Aisha',
    birthDate: DateTime(2026, 6, 10),
    gender: Gender.female,
  );

  Future<ProviderContainer> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          childrenProvider.overrideWith((ref) => Stream.value([child])),
        ],
        child: const ChildHealthApp(),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ChildHealthApp)),
    );
    await container.read(reminderRepositoryProvider).add(
          Reminder(
            id: '',
            childId: 'c1',
            type: ReminderType.medication,
            title: 'Витамин D',
            scheduledTime: DateTime.now().add(const Duration(hours: 3)),
          ),
        );
    await tester.pumpAndSettle();

    final l = await AppLocalizations.delegate.load(defaultLocale);
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.navReminders));
    await tester.pumpAndSettle();

    // Scrolled clear of the tab bar before anything is tapped. The shell lets
    // the page run under the frosted bar, so a row resting in the bottom
    // eighty pixels is a row whose taps the bar takes — and the bar
    // navigates, which is what «нажал, и оно исчезло» actually was.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -160));
    await tester.pumpAndSettle();

    return container;
  }

  List<Reminder> remindersOf(ProviderContainer c) =>
      c.read(remindersProvider).value ?? const [];

  testWidgets('a tap on the name opens it for editing and completes nothing', (
    tester,
  ) async {
    final container = await pump(tester);

    // The very start of the title, which is where the checkbox's invisible
    // tap area used to reach.
    await tester.tap(find.text('Витамин D'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(remindersOf(container).single.isCompleted, isFalse);
  });

  testWidgets('the row is still on the list after that tap', (tester) async {
    final container = await pump(tester);

    await tester.tap(find.text('Витамин D'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(BottomSheet))).pop();
    await tester.pumpAndSettle();

    expect(find.text('Витамин D'), findsOneWidget);
    expect(remindersOf(container), hasLength(1));
  });

  testWidgets('ticking it off says so and can be taken back', (tester) async {
    final container = await pump(tester);
    final l = await AppLocalizations.delegate.load(defaultLocale);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    // It left the list, and the strip explains why rather than leaving a
    // parent to wonder where it went.
    expect(remindersOf(container).single.isCompleted, isTrue);
    expect(find.text(l.reminderCompleted), findsOneWidget);

    await tester.tap(find.text(l.commonUndo));
    await tester.pumpAndSettle();

    expect(remindersOf(container).single.isCompleted, isFalse);
    expect(find.text('Витамин D'), findsOneWidget);
  });

  testWidgets('deleting asks first, and a refusal keeps it', (tester) async {
    final container = await pump(tester);
    final l = await AppLocalizations.delegate.load(defaultLocale);

    await tester.tap(find.text('Витамин D'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, l.reminderDelete));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, l.commonCancel));
    await tester.pumpAndSettle();

    expect(remindersOf(container), hasLength(1));
  });

  testWidgets('and goes through when it is confirmed', (tester) async {
    final container = await pump(tester);
    final l = await AppLocalizations.delegate.load(defaultLocale);

    await tester.tap(find.text('Витамин D'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, l.reminderDelete));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l.commonDelete));
    await tester.pumpAndSettle();

    expect(remindersOf(container), isEmpty);
  });
}
