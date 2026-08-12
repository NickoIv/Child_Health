import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/features/assistant/assistant_nav_icon.dart';
import 'package:child_health_tracker/core/care/conversation_memory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The thread, on this phone, for a week.
///
/// It used to be one question and no answers. That was enough to pick a
/// thought back up and not enough for what a parent actually does: ask on
/// Tuesday «он третью ночь плохо спит» and on Thursday «а сейчас лучше?».
/// What is tested is still mostly the limits — it forgets, it trims, and it
/// goes when she says so.
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

    test('keeps the exchange, question and answer both', () async {
      final c = container();
      final memory = c.read(conversationMemoryProvider.notifier);

      await memory.remember(question, now: asked);
      await memory.answered('Около 14 часов в сутки.', now: asked);

      final thread = c.read(conversationMemoryProvider);
      expect(thread, hasLength(1));
      expect(thread.single.question, question);
      expect(thread.single.answer, 'Около 14 часов в сутки.');
    });

    test('remembers the question even when no answer arrived', () async {
      // The point at which a phone gets put down. A question she asked is
      // worth keeping whether or not the reply came back.
      final c = container();
      await c
          .read(conversationMemoryProvider.notifier)
          .remember(question, now: asked);

      expect(c.read(conversationMemoryProvider).single.answer, isEmpty);
    });

    test('holds a few exchanges and then forgets the oldest', () async {
      final c = container();
      final memory = c.read(conversationMemoryProvider.notifier);

      for (var i = 0; i < conversationTurnLimit + 3; i++) {
        await memory.remember('Вопрос $i', now: asked);
      }

      final thread = c.read(conversationMemoryProvider);
      expect(thread, hasLength(conversationTurnLimit));
      expect(thread.first.question, isNot('Вопрос 0'));
      expect(thread.last.question, 'Вопрос ${conversationTurnLimit + 2}');
    });

    test('trims an answer that runs to a page', () async {
      final c = container();
      final memory = c.read(conversationMemoryProvider.notifier);

      await memory.remember(question, now: asked);
      await memory.answered('я' * 5000, now: asked);

      expect(
        c.read(conversationMemoryProvider).single.answer.length,
        lessThanOrEqualTo(conversationAnswerMax + 1),
      );
    });

    test('blank input is not worth remembering', () async {
      final c = container();
      await c.read(conversationMemoryProvider.notifier).remember('   ');

      expect(c.read(conversationMemoryProvider), isEmpty);
    });

    test('forgetting clears it from disk too', () async {
      final c = container();
      final memory = c.read(conversationMemoryProvider.notifier);

      await memory.remember(question, now: asked);
      await memory.forget();

      expect(c.read(conversationMemoryProvider), isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('chat_thread'), isNull);
    });

    test('it survives a restart while it is still fresh', () async {
      final c = container();
      await c
          .read(conversationMemoryProvider.notifier)
          .remember(question, now: DateTime.now());

      final next = container();
      next.read(conversationMemoryProvider);
      await Future<void>.delayed(Duration.zero);

      expect(next.read(conversationMemoryProvider).single.question, question);
    });

    test('and a thread from last month does not come back', () async {
      // Older than a week is a stranger quoting you back to yourself, and the
      // child has changed under it.
      SharedPreferences.setMockInitialValues({
        'chat_thread':
            '[{"q":"Старый вопрос","a":"","at":"2020-01-01T10:00:00.000"}]',
      });

      final c = container();
      c.read(conversationMemoryProvider);
      await Future<void>.delayed(Duration.zero);

      expect(c.read(conversationMemoryProvider), isEmpty);
    });

    test('a key written by an older build is not a crash', () async {
      SharedPreferences.setMockInitialValues({'chat_thread': 'not json'});

      final c = container();
      c.read(conversationMemoryProvider);
      await Future<void>.delayed(Duration.zero);

      expect(c.read(conversationMemoryProvider), isEmpty);
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

    expect(
      container.read(conversationMemoryProvider).single.question,
      question,
    );
  });
}
