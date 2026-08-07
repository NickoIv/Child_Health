import 'dart:convert';

import 'package:child_health_tracker/ai/assistant_service.dart';
import 'package:child_health_tracker/ai/child_snapshot.dart';
import 'package:child_health_tracker/ai/prompt.dart';
import 'package:child_health_tracker/ai/rag.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _endpoint = 'https://example.invalid/ai';

/// Records whether the network was touched at all — the central assertion for
/// the emergency gate.
class _Spy {
  int calls = 0;
  Map<String, dynamic>? lastBody;

  http.Client client({
    int status = 200,
    Map<String, dynamic> Function()? response,
  }) {
    return MockClient((request) async {
      calls++;
      lastBody = jsonDecode(request.body) as Map<String, dynamic>;
      final payload = response?.call() ?? {'text': 'Ответ помощника.'};
      // bodyBytes, not body: the service decodes UTF-8 itself, and Cyrillic
      // would otherwise come back mangled exactly as it would in production.
      return http.Response.bytes(
        utf8.encode(jsonEncode(payload)),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
  }
}

void main() {
  group('emergency gate', () {
    // The single most important property in the AI layer: a question that
    // describes a red flag must never reach a language model, because a
    // plausible reassuring answer to "ребёнок не дышит" can kill.
    const redFlagQuestions = [
      'ребёнок не дышит что делать',
      'малыш посинел и обмяк',
      'у ребёнка судороги',
      // Feminine forms matter: a mother writing about her daughter does not
      // type the masculine verb.
      'дочка подавилась виноградом',
      'дочь упала с дивана',
      'она ударилась головой',
      'сын проглотил батарейку от пульта',
      'сыпь не бледнеет под стаканом',
      'рвота с кровью',
      'зеленая рвота у малыша',
      'ребёнок ударился головой и его рвёт',
      'малышка обварилась кипятком',
    ];

    for (final q in redFlagQuestions) {
      test('"$q" never reaches the model', () async {
        final spy = _Spy();
        final service = GeminiAssistantService(
          client: spy.client(),
          endpoint: _endpoint,
        );

        final reply = await service.ask(question: q, ageMonths: 6);

        expect(reply, isA<AssistantEmergency>());
        expect(
          spy.calls,
          0,
          reason: 'the network must not be touched for a red flag',
        );
      });
    }

    test('the gate also fires when the assistant is not configured', () async {
      const service = DisabledAssistantService();
      final reply = await service.ask(question: 'ребёнок не дышит');
      expect(reply, isA<AssistantEmergency>());
    });

    test('the matched phrase is reported back', () async {
      const service = DisabledAssistantService();
      final reply =
          await service.ask(question: 'малыш посинел, что делать')
              as AssistantEmergency;
      expect(reply.matched, contains('посинел'));
    });

    test('is case-insensitive', () {
      expect(detectEmergencyPhrases('РЕБЁНОК НЕ ДЫШИТ'), isNotEmpty);
    });

    test('an ordinary question is not flagged', () {
      for (final q in const [
        'когда вводить прикорм',
        'сколько должен спать ребёнок',
        'температура 38 что делать',
        'можно ли парацетамол',
      ]) {
        expect(
          detectEmergencyPhrases(q),
          isEmpty,
          reason: '"$q" must not be treated as an emergency',
        );
      }
    });
  });

  group('normal questions', () {
    test('reach the proxy and return the answer', () async {
      final spy = _Spy();
      final service = GeminiAssistantService(
        client: spy.client(),
        endpoint: _endpoint,
      );

      final reply =
          await service.ask(question: 'когда вводить прикорм', ageMonths: 5)
              as AssistantAnswer;

      expect(spy.calls, 1);
      expect(reply.text, 'Ответ помощника.');
      expect(reply.sources, isNotEmpty);
    });

    test('send the system prompt and the retrieved knowledge', () async {
      final spy = _Spy();
      final service = GeminiAssistantService(
        client: spy.client(),
        endpoint: _endpoint,
      );

      await service.ask(question: 'температура у ребёнка', ageMonths: 8);

      final body = spy.lastBody!;
      expect(body['system'], systemPrompt);
      final prompt = body['prompt'] as String;
      expect(prompt, contains('БАЗА ЗНАНИЙ'));
      expect(prompt, contains('ВОПРОС РОДИТЕЛЯ'));
      expect(prompt, contains('Температура у ребёнка'));
    });

    test('include the child context when there is one', () async {
      final spy = _Spy();
      final service = GeminiAssistantService(
        client: spy.client(),
        endpoint: _endpoint,
      );

      await service.ask(
        question: 'сколько спать',
        ageMonths: 6,
        childContext: childSnapshot(
          child: Child(
            id: 'c',
            parentUid: 'u',
            name: 'Айгерим',
            birthDate: DateTime(2026, 2, 2),
            gender: Gender.female,
          ),
          now: DateTime(2026, 8, 2),
        ),
      );

      final prompt = spy.lastBody!['prompt'] as String;
      expect(prompt, contains('КОНТЕКСТ РЕБЁНКА'));
      expect(prompt, contains('Айгерим'));
      expect(prompt, contains('6 мес.'));
    });

    test('an empty question is rejected without a call', () async {
      final spy = _Spy();
      final service = GeminiAssistantService(
        client: spy.client(),
        endpoint: _endpoint,
      );
      final reply = await service.ask(question: '   ');
      expect(reply, isA<AssistantUnavailable>());
      expect(spy.calls, 0);
    });
  });

  group('failure handling', () {
    test('a quota error is explained in plain Russian', () async {
      final spy = _Spy();
      final service = GeminiAssistantService(
        client: spy.client(status: 429, response: () => {'error': 'quota'}),
        endpoint: _endpoint,
      );
      final reply =
          await service.ask(question: 'прикорм') as AssistantUnavailable;
      expect(reply.reason, contains('Слишком много запросов'));
    });

    test('a transient 502 is retried once and then succeeds', () async {
      // A freshly deployed Worker answers 502 for a few seconds while the new
      // version propagates. Observed live, not hypothetical.
      var attempt = 0;
      final client = MockClient((request) async {
        attempt++;
        final payload = attempt == 1
            ? {'error': 'upstream'}
            : {'text': 'Ответ со второй попытки.'};
        return http.Response.bytes(
          utf8.encode(jsonEncode(payload)),
          attempt == 1 ? 502 : 200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = GeminiAssistantService(
        client: client,
        endpoint: _endpoint,
      );
      final reply =
          await service.ask(question: 'прикорм') as AssistantAnswer;

      expect(attempt, 2);
      expect(reply.text, 'Ответ со второй попытки.');
    });

    test('a persistent 502 gives up after one retry', () async {
      var attempt = 0;
      final client = MockClient((request) async {
        attempt++;
        return http.Response.bytes(
          utf8.encode(jsonEncode({'error': 'upstream'})),
          502,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = GeminiAssistantService(
        client: client,
        endpoint: _endpoint,
      );
      final reply =
          await service.ask(question: 'прикорм') as AssistantUnavailable;

      expect(attempt, 2, reason: 'exactly one retry, not a loop');
      expect(reply.reason, contains('недоступен'));
    });

    test('a server error does not leak the raw status text', () async {
      final spy = _Spy();
      final service = GeminiAssistantService(
        client: spy.client(status: 502, response: () => {'error': 'upstream'}),
        endpoint: _endpoint,
      );
      final reply =
          await service.ask(question: 'прикорм') as AssistantUnavailable;
      expect(reply.reason, contains('недоступен'));
      expect(reply.reason, isNot(contains('upstream')));
    });

    test('an empty model reply is reported rather than shown blank', () async {
      final spy = _Spy();
      final service = GeminiAssistantService(
        client: spy.client(response: () => {'text': '   '}),
        endpoint: _endpoint,
      );
      final reply =
          await service.ask(question: 'прикорм') as AssistantUnavailable;
      expect(reply.reason, contains('пустой ответ'));
    });

    test('no endpoint means a configuration message, not a crash', () async {
      final service = GeminiAssistantService(endpoint: '');
      expect(service.isConfigured, isFalse);
      final reply =
          await service.ask(question: 'прикорм') as AssistantUnavailable;
      expect(reply.isConfigurationIssue, isTrue);
    });
  });

  group('retrieval', () {
    test('finds the article that answers the question', () {
      final context = retrieveFor('температура 38', ageMonths: 8);
      expect(context.articles.map((a) => a.id), contains('fever'));
      expect(context.promptBlock, contains('ЧТО ДЕЛАТЬ СЕЙЧАС'));
      expect(context.promptBlock, contains('КОГДА К ВРАЧУ'));
      expect(context.promptBlock, contains('ИСТОЧНИКИ'));
    });

    test('carries the red flags into the prompt', () {
      final context = retrieveFor('температура у грудничка', ageMonths: 1);
      expect(context.promptBlock, contains('СКОРАЯ ПОМОЩЬ'));
    });

    test('falls back to age-relevant basics for an unplaceable question', () {
      final context = retrieveFor('абракадабра непонятная', ageMonths: 3);
      expect(
        context.articles,
        isNotEmpty,
        reason: 'an empty context makes the model refuse even simple things',
      );
    });

    test('respects the limit', () {
      final context = retrieveFor('ребёнок', ageMonths: 6, limit: 2);
      expect(context.articles.length, lessThanOrEqualTo(2));
    });
  });

  group('system prompt guardrails', () {
    // The base is no longer the only thing the model may answer from — it
    // outranks the model where it has something and is silent where it does
    // not. See assistant_topics_test.dart for the whole shape of that.
    test('prefers the base over the model on health', () {
      expect(systemPrompt, contains('БАЗА ЗНАНИЙ'));
      expect(systemPrompt, contains('Он\n  проверен, твоя память нет'));
    });

    test('forbids diagnosing and prescribing', () {
      expect(systemPrompt, contains('Не ставь диагноз по переписке'));
      expect(systemPrompt, contains('Называя лекарство, не назначай его'));
    });

    test('requires pointing at a doctor', () {
      expect(systemPrompt, contains('идут к врачу'));
    });

    test('forbids talking a worried parent down', () {
      expect(systemPrompt, contains('Не преуменьшай тревогу родителя'));
      expect(systemPrompt, contains('не отговаривай от визита к врачу'));
    });
  });
}
