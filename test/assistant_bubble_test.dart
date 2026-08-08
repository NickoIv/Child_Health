import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/core/theme/glass.dart';
import 'package:child_health_tracker/features/assistant/assistant_bubble.dart';
import 'package:child_health_tracker/features/assistant/chat_screen.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// «Может помощника вообще вывести в кнопку на всех окнах — мало ли какой
/// вопрос возникнет.»
///
/// Reaching the assistant used to be three taps from anywhere that was not the
/// assistant tab. The bubble is one, from everywhere.
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

  testWidgets('it is on every tab', (tester) async {
    final l = await pumpPhone(tester);

    expect(find.byType(AssistantBubble), findsOneWidget);

    for (final tab in [l.navDiary, l.navAssistant, l.navFamily]) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(find.byType(AssistantBubble), findsOneWidget, reason: tab);
    }
  });

  testWidgets('and behind «Ещё» as well', (tester) async {
    await pumpPhone(tester);

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Дети'));
    await tester.pumpAndSettle();

    expect(find.byType(AssistantBubble), findsOneWidget);
  });

  testWidgets('one tap opens the chat', (tester) async {
    await pumpPhone(tester);

    await tester.tap(find.byType(AssistantBubble));
    await tester.pumpAndSettle();

    expect(find.byType(ChatScreen), findsOneWidget);
  });

  testWidgets('and it is not drawn on top of the chat itself', (tester) async {
    await pumpPhone(tester);

    await tester.tap(find.byType(AssistantBubble));
    await tester.pumpAndSettle();

    // A button that opens the screen you are looking at is furniture.
    expect(find.byType(AssistantBubble), findsNothing);
  });

  testWidgets('it clears the glass and the screen\'s own button', (
    tester,
  ) async {
    final l = await pumpPhone(tester);
    await tester.tap(find.text(l.navDiary).last);
    await tester.pumpAndSettle();

    final bubble = tester.getRect(find.byType(AssistantBubble));
    final panel = tester.getRect(find.byType(GlassPanel));
    final fab = tester.getRect(find.byType(FloatingActionButton));

    expect(bubble.bottom, lessThanOrEqualTo(panel.top));
    // Left corner, and the diary's «Добавить запись» is on the right. They
    // must not overlap on the narrowest phone the app supports.
    expect(bubble.right, lessThan(fab.left));
  });

  testWidgets('it rests rather than pulsing forever', (tester) async {
    await pumpPhone(tester);

    // The first version repeated, which meant every `pumpAndSettle` in the
    // suite waited on it — two hundred tests timed out. Reaching this line at
    // all is the assertion; the expect only says so out loud.
    await tester.pumpAndSettle();
    expect(find.byType(AssistantBubble), findsOneWidget);
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

    expect(find.byType(AssistantBubble), findsOneWidget);
    // The halo is what moves, so with animations off it is simply not built.
    expect(
      find.descendant(
        of: find.byType(AssistantBubble),
        matching: find.byType(AnimatedBuilder),
      ),
      findsNothing,
    );
  });
}
