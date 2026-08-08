import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/features/assistant/assistant_nav_icon.dart';
import 'package:child_health_tracker/features/assistant/chat_screen.dart';
import 'package:child_health_tracker/features/shell/app_shell.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// «Кнопка перекрывает информацию на экране. Может добавить её в нижнее меню
/// рядом с другими… кнопку нужно под правую руку расположить.»
///
/// The floating version lasted half a day and he was right about it: a control
/// that is on every screen belongs in the furniture, not on top of the
/// content. This is where it went, and what it does there.
void main() {
  setUpAll(initializeDateFormatting);

  Future<AppLocalizations> pumpPhone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: ChildHealthApp()));
    await tester.pumpAndSettle();
    return AppLocalizations.delegate.load(defaultLocale);
  }

  testWidgets('it sits in the bar, not over the page', (tester) async {
    await pumpPhone(tester);

    expect(find.byType(AssistantNavIcon), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byType(AssistantNavIcon),
      ),
      findsOneWidget,
    );
  });

  testWidgets('and it is the rightmost thing in it', (tester) async {
    final l = await pumpPhone(tester);

    final icon = tester.getRect(find.byType(AssistantNavIcon));
    // Under the right thumb: every other destination is to its left.
    for (final label in [l.navDashboard, l.navDiary, l.navMore]) {
      final other = tester.getRect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
      );
      expect(other.left, lessThan(icon.left), reason: label);
    }
  });

  testWidgets('it is on every tab', (tester) async {
    final l = await pumpPhone(tester);

    for (final tab in [l.navDiary, l.navAssistant, l.navFamily]) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(find.byType(AssistantNavIcon), findsOneWidget, reason: tab);
    }
  });

  testWidgets('one tap opens the chat in a window of its own', (tester) async {
    final l = await pumpPhone(tester);

    await tester.tap(find.byType(AssistantNavIcon));
    await tester.pumpAndSettle();

    expect(find.byType(ChatScreen), findsOneWidget);
    // A window, not a tab: no bar under the conversation, and no way to lose
    // it by tapping one.
    expect(find.byType(AppShell), findsNothing);
    expect(find.text(l.chatTitle), findsOneWidget);
  });

  testWidgets('closing it comes back to where the question was asked', (
    tester,
  ) async {
    final l = await pumpPhone(tester);
    await tester.tap(find.text(l.navFamily).last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AssistantNavIcon));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Back on the family tab, not thrown to the home screen.
    expect(find.byType(ChatScreen), findsNothing);
    expect(find.text(l.navFamily), findsWidgets);
  });

  testWidgets('the article search still reaches it', (tester) async {
    final l = await pumpPhone(tester);
    await tester.tap(find.text(l.navAssistant).last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'какая погода');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l.assistantAskAi));
    await tester.pumpAndSettle();

    // Its link is the old `/assistant/chat`, which now redirects — a bookmark
    // and a history entry both have to keep working.
    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.text('какая погода', skipOffstage: false), findsWidgets);
  });

  testWidgets('it rests rather than pulsing forever', (tester) async {
    await pumpPhone(tester);

    // The floating version repeated, which meant every `pumpAndSettle` in the
    // suite waited on it — two hundred tests timed out. Reaching this line is
    // the assertion.
    await tester.pumpAndSettle();
    expect(find.byType(AssistantNavIcon), findsOneWidget);
  });

  testWidgets('a parent who asked for less movement gets a still one', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: ChildHealthApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AssistantNavIcon), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AssistantNavIcon),
        matching: find.byType(AnimatedBuilder),
      ),
      findsNothing,
    );
  });
}
