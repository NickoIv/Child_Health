import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/features/assistant/assistant_screen.dart';
import 'package:child_health_tracker/features/dashboard/dashboard_screen.dart';
import 'package:child_health_tracker/features/dashboard/reflection_card.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// «Во вкладке Помощник тоже нужно упорядочить, слишком загружено информацией.»
///
/// It was one scroll carrying the whole knowledge base *and* every analytical
/// card in the app. The fix is not smaller cards: it is admitting the tab is
/// two things — what you look up, and what you read — and only ever drawing
/// one of them. What this holds is the "only one" half, which is the entire
/// point and the easiest thing to lose to a stray widget.
void main() {
  setUpAll(initializeDateFormatting);

  Future<AppLocalizations> openAssistant(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: ChildHealthApp()));
    await tester.pumpAndSettle();

    final l = await AppLocalizations.delegate.load(defaultLocale);
    await tester.tap(find.text(l.navAssistant).last);
    await tester.pumpAndSettle();
    return l;
  }

  testWidgets('it opens on the half you came looking for', (tester) async {
    final l = await openAssistant(tester);

    // Both names are on screen — the switch is the compaction, and a switch
    // nobody can see is just a hidden page.
    expect(find.text(l.assistantViewKnowledge), findsOneWidget);
    expect(find.text(l.assistantViewInsights), findsOneWidget);

    expect(find.text(l.assistantTriage), findsOneWidget);
    // Further down the same half, so it takes a scroll to reach — which is
    // fine, and is the difference between a long page and two of them.
    await tester.scrollUntilVisible(
      find.text(l.assistantAllTopics),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(l.assistantAllTopics), findsOneWidget);
  });

  testWidgets('the reading half is not drawn underneath it', (tester) async {
    await openAssistant(tester);

    // The whole complaint in one assertion: the analytical cards used to be
    // below the knowledge base on the same scroll.
    expect(find.byType(ReflectionCard), findsNothing);
    expect(find.byType(DashboardBlocks), findsNothing);
  });

  testWidgets('and the library is not drawn under the reading half', (
    tester,
  ) async {
    final l = await openAssistant(tester);

    await tester.tap(find.text(l.assistantViewInsights));
    await tester.pumpAndSettle();

    expect(find.text(l.assistantTriage), findsNothing);
    expect(find.text(l.assistantAllTopics), findsNothing);
    expect(find.text(l.assistantDisclaimer), findsNothing);
  });

  testWidgets('searching answers the question the switch is for', (
    tester,
  ) async {
    final l = await openAssistant(tester);

    await tester.enterText(find.byType(TextField).first, 'температура');
    await tester.pumpAndSettle();

    // With results on screen the switch has nothing to offer, so it steps out
    // of the way rather than sitting above them.
    expect(find.text(l.assistantViewKnowledge), findsNothing);
    expect(find.text(l.assistantViewInsights), findsNothing);
  });

  group('the search field is not a dead end', () {
    // He typed «какая погода сегодня?» into it — it is the most prominent
    // input on the tab — and got «Ничего не нашлось», with a full assistant
    // one tap away that he had no way of knowing about from that screen.
    const question = 'какая погода сегодня?';

    testWidgets('a query with no article offers the assistant', (tester) async {
      final l = await openAssistant(tester);

      await tester.enterText(find.byType(TextField).first, question);
      await tester.pumpAndSettle();

      expect(find.text(l.assistantNothingFound), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, l.assistantAskAi),
        findsOneWidget,
      );
      // And the empty state says what the field actually searches, instead of
      // suggesting another word for a question no word will find.
      expect(find.text(l.assistantSearchIsArticles), findsOneWidget);
    });

    testWidgets('and carries the words across', (tester) async {
      final l = await openAssistant(tester);

      await tester.enterText(find.byType(TextField).first, question);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, l.assistantAskAi));
      await tester.pumpAndSettle();

      // The chat, with the question already asked — not an empty field and a
      // request to type it again.
      expect(find.text(l.chatTitle), findsOneWidget);
      // `skipOffstage: false`: the shell cross-fades between tabs, so the
      // outgoing one is still in the tree for a frame and the finder's default
      // would skip the incoming bubble along with it.
      expect(find.text(question, skipOffstage: false), findsWidgets);
    });

    testWidgets('a query that does find articles offers it too', (
      tester,
    ) async {
      final l = await openAssistant(tester);

      await tester.enterText(find.byType(TextField).first, 'температура');
      await tester.pumpAndSettle();

      expect(find.text(l.assistantFound), findsOneWidget);
      expect(find.widgetWithText(TextButton, l.assistantAskAi), findsOneWidget);
    });
  });

  test('there are exactly two halves', () {
    // A third would be a menu, and a menu is what this replaced.
    expect(AssistantView.values.length, 2);
  });
}
