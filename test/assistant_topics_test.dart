import 'dart:convert';

import 'package:child_health_tracker/ai/assistant_service.dart';
import 'package:child_health_tracker/ai/prompt.dart';
import 'package:child_health_tracker/ai/topics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// «Я хочу полноценного ИИ помощника, который будет отвечать на любые
/// вопросы.»
///
/// This file used to test a gate: two word lists that decided, before the
/// model was called, whether a question was medical or everyday — and anything
/// unrecognised was treated as medical, which meant answered from forty-seven
/// articles or refused. The gate is gone, and so is everything here that
/// tested it.
///
/// What is left is the shape of what replaced it: one prompt that answers
/// anything, the base preferred where it has something, and the one interlock
/// that never cost an answer — the deterministic red-flag check.
void main() {
  const endpoint = 'https://example.invalid/ai';

  group('the prompt', () {
    test('forbids the refusals the old one required', () {
      // Each of these was a sentence the assistant was previously instructed
      // to produce, and each is what «заготовленные ответы» looked like.
      expect(systemPrompt, contains('Отвечай на любой вопрос'));
      expect(systemPrompt, contains('это не моя тема'));
      expect(systemPrompt, contains('в моей базе нет ответа на этот вопрос'));
      expect(systemPrompt, contains('Такого ответа больше не существует'));
    });

    test('does not tell the model to stay on the subject of children', () {
      // The line that used to end everything off-topic.
      expect(
        systemPrompt,
        isNot(contains('Отвечать на вопросы, не связанные со здоровьем')),
      );
      expect(
        systemPrompt,
        isNot(contains('Не отвечай на вопросы, не связанные с ребёнком')),
      );
      expect(
        systemPrompt,
        isNot(contains('Не добавляй ничего из собственных знаний')),
      );
    });

    test('still prefers the base where the base has something', () {
      expect(systemPrompt, contains('Он\n  проверен, твоя память нет'));
    });

    test('keeps what protects somebody rather than what refuses them', () {
      expect(systemPrompt, contains('Не ставь диагноз по переписке'));
      expect(systemPrompt, contains('Называя лекарство, не назначай его'));
      expect(systemPrompt, contains('«на глаз» не выдумывай'));
      expect(systemPrompt, contains('не отговаривай от визита к врачу'));
    });

    test('keeps the context, the format and the actions', () {
      expect(systemPrompt, contains('КОНТЕКСТ РЕБЁНКА'));
      expect(systemPrompt, contains('ДЕЙСТВИЯ В ПРИЛОЖЕНИИ'));
      expect(systemPrompt, contains('Запрещены: markdown'));
    });

    test('an empty base reads as a fact, not as an answer to give back', () {
      final built = buildUserPrompt(
        question: 'как вывести пятно от смеси',
        knowledgeBlock: '',
      );
      expect(built, contains('отвечай своими знаниями'));
      expect(built, isNot(contains('нет ответа')));
    });
  });

  group('what the service sends', () {
    Map<String, dynamic>? sent;

    http.Client client() => MockClient((request) async {
      sent = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response.bytes(
        utf8.encode(jsonEncode({'text': 'Ответ.'})),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    setUp(() => sent = null);

    test('one prompt, whatever the question is about', () async {
      final service = GeminiAssistantService(
        client: client(),
        endpoint: endpoint,
      );

      for (final q in const [
        'температура 38',
        'как встать в очередь в садик',
        'сколько варить гречку',
        'напиши поздравление бабушке',
        'что такое ипотека простыми словами',
      ]) {
        final reply = await service.ask(question: q, ageMonths: 6);
        expect(reply, isA<AssistantAnswer>(), reason: q);
        expect(sent!['system'], systemPrompt, reason: q);
      }
    });

    test('a question the base covers carries its articles', () async {
      final service = GeminiAssistantService(
        client: client(),
        endpoint: endpoint,
      );
      final reply =
          await service.ask(question: 'температура 38', ageMonths: 6)
              as AssistantAnswer;

      expect(reply.mode, AnswerMode.fromBase);
      expect(reply.sources, isNotEmpty);
      expect(reply.isFromGeneralKnowledge, isFalse);
    });

    test('one the base does not is answered anyway, and says so', () async {
      final service = GeminiAssistantService(
        client: client(),
        endpoint: endpoint,
      );
      final reply =
          await service.ask(question: 'сколько варить гречку', ageMonths: 6)
              as AssistantAnswer;

      expect(reply.mode, AnswerMode.general);
      // And is not dressed in four unrelated paediatric articles, which is
      // what the old age fallback did to every question it could not place.
      expect(reply.sources, isEmpty);
      expect(reply.isFromGeneralKnowledge, isTrue);
    });

    test('the emergency gate still runs before any of this', () async {
      var calls = 0;
      final service = GeminiAssistantService(
        client: MockClient((_) async {
          calls++;
          return http.Response('{}', 200);
        }),
        endpoint: endpoint,
      );

      // The one thing that did not get looser. It is deterministic, it runs
      // before the model, and it costs an ordinary question nothing.
      final reply = await service.ask(
        question: 'в садике он упал с горки и не реагирует',
      );
      expect(reply, isA<AssistantEmergency>());
      expect(calls, 0);
    });
  });
}
