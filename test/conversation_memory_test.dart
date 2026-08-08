import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/features/assistant/assistant_nav_icon.dart';
import 'package:child_health_tracker/core/care/conversation_memory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One question, on this phone, for one day. What is tested is mostly the
/// smallness of it: no answers kept, no history, and nothing at all once the
/// day is out or she has said she is done.
void main() {
  setUpAll(initializeDateFormatting);

  final asked = DateTime(2026, 8, 2, 14);
  const question = 'Сколько должен спать ребёнок в 6 месяцев';

  group('what is remembered', () {
    test('a question stays fresh for a day', () {
      final last = LastQuestion(text: question, askedAt: asked);

      expect(last.isFreshAt(asked.add(const Duration(minutes: 5))), isTrue);
      expect(last.isFreshAt(asked.add(const Duration(hours: 23))), isTrue);
    });

    test('and is stale after it', () {
      final last = LastQuestion(text: question, askedAt: asked);

      expect(last.isFreshAt(asked.add(const Duration(hours: 24))), isFalse);
      expect(last.isFreshAt(asked.add(const Duration(days: 3))), isFalse);
    });

    test('a clock that has gone backwards is not a fresh question', () {
      final last = LastQuestion(text: question, askedAt: asked);
      expect(last.isFreshAt(asked.subtract(const Duration(hours: 1))), isFalse);
    });
  });

  group('the store', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    ProviderContainer container() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      return c;
    }

    test('keeps only the latest question, never a history', () async {
      final c = container();
      final memory = c.read(conversationMemoryProvider.notifier);

      await memory.remember('Первый вопрос', now: asked);
      await memory.remember(question, now: asked);

      expect(c.read(conversationMemoryProvider)!.text, question);

      // Nothing but the one question and its time is on disk.
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getKeys().where((k) => k.startsWith('chat_')).length,
        2,
      );
    });

    test('blank input is not worth remembering', () async {
      final c = container();
      await c.read(conversationMemoryProvider.notifier).remember('   ');

      expect(c.read(conversationMemoryProvider), isNull);
    });

    test('forgetting clears it from disk too', () async {
      final c = container();
      final memory = c.read(conversationMemoryProvider.notifier);

      await memory.remember(question, now: asked);
      await memory.forget();

      expect(c.read(conversationMemoryProvider), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('chat_last_question'), isNull);
    });

    test('it survives a restart while it is still fresh', () async {
      SharedPreferences.setMockInitialValues({
        'chat_last_question': question,
        'chat_last_question_at': asked.toIso8601String(),
      });

      final c = container();
      // The notifier loads from disk after its first build.
      c.read(conversationMemoryProvider);
      await Future<void>.delayed(Duration.zero);

      expect(c.read(conversationMemoryProvider)?.text, question);
    });
  });


  testWidgets('asking on the chat screen is what fills the memory', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return const ChildHealthApp();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Straight into the chat: it is one tap from anywhere now.
    await tester.tap(find.byType(AssistantNavIcon));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, question);
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pumpAndSettle();

    expect(container.read(conversationMemoryProvider)?.text, question);
  });
}
