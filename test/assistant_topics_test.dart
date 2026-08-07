import 'dart:convert';

import 'package:child_health_tracker/ai/assistant_service.dart';
import 'package:child_health_tracker/ai/prompt.dart';
import 'package:child_health_tracker/ai/topics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Step C: the assistant may answer everyday questions from what it knows,
/// and medicine still comes only from the forty-seven vetted articles.
///
/// The whole feature rests on one property — which side of that line a
/// question lands on is decided here, in Dart, before anything is sent. So
/// that is what most of this file is about.
void main() {
  const endpoint = 'https://example.invalid/ai';

  group('the topic gate', () {
    test('anything about health is answered from the base', () {
      for (final q in const [
        'температура 37.5 второй день',
        'у него сыпь на щеках',
        'можно ли ибупрофен в 8 месяцев',
        'когда делать прививку от кори',
        'сколько раз кормить в 4 месяца',
        'когда вводить прикорм',
        'он не спит всю ночь',
        'ребёнок мало весит, весит 6 кг в год',
        'болит живот после еды',
        'нормально ли что он ещё не ползает',
        'какие капли в нос можно',
        'что за анализ назначил врач',
      ]) {
        expect(
          modeFor(q),
          AnswerMode.medical,
          reason: '«$q» must stay on the vetted base',
        );
      }
    });

    test('the four everyday topics are allowed through', () {
      for (final q in const [
        'как встать в очередь в садик',
        'какие документы нужны на пособие',
        'когда отучать от соски',
        'как построить режим дня',
        'какое автокресло выбрать',
        'что взять в поездку с ребёнком',
        'он закатывает истерики в магазине',
        'сколько можно смотреть мультики',
      ]) {
        expect(
          modeFor(q),
          AnswerMode.everyday,
          reason: '«$q» is not a medical question',
        );
      }
    });

    test('a medical word inside a domestic question wins', () {
      // The dangerous shape: it reads like a nursery question and is not.
      expect(modeFor('можно ли в садик с температурой'), AnswerMode.medical);
      expect(modeFor('соска и прикус зубов'), AnswerMode.medical);
      expect(
        modeFor('какие документы нужны для прививки'),
        AnswerMode.medical,
      );
      expect(
        modeFor('режим дня когда ребёнок болеет'),
        AnswerMode.medical,
      );
    });

    test('a question the lists do not know is treated as medical', () {
      // Silence is not permission. Strict is the default and the fallback.
      expect(modeFor('абракадабра'), AnswerMode.medical);
      expect(modeFor(''), AnswerMode.medical);
      expect(modeFor('что думаешь'), AnswerMode.medical);
    });

    test('ё and е are the same letter here', () {
      expect(modeFor('ребенок весит мало'), AnswerMode.medical);
      expect(modeFor('РЕБЁНОК ВЕСИТ МАЛО'), AnswerMode.medical);
    });
  });

  group('the two prompts', () {
    test('the medical one is unchanged in what it forbids', () {
      final p = systemPromptFor(AnswerMode.medical);
      expect(p, systemPrompt);
      expect(p, contains('ТОЛЬКО на основании'));
      expect(p, contains('Не добавляй ничего из собственных знаний'));
      expect(p, contains('Ставить диагноз'));
    });

    test('the everyday one never lets its own knowledge near medicine', () {
      final p = systemPromptFor(AnswerMode.everyday);
      expect(p, contains('ГРАНИЦА, КОТОРУЮ НЕЛЬЗЯ ПЕРЕХОДИТЬ'));
      expect(p, contains('Про здоровье я отвечаю'));
      expect(p, contains('Никогда не называй лекарств'));
      expect(p, contains('Никогда не ставь диагноз'));
      expect(p, isNot(contains('Не добавляй ничего из собственных знаний')));
    });

    test('both keep the format, the child context and the actions', () {
      for (final mode in AnswerMode.values) {
        final p = systemPromptFor(mode);
        expect(p, contains('КОНТЕКСТ РЕБЁНКА'));
        expect(p, contains('ДЕЙСТВИЯ В ПРИЛОЖЕНИИ'));
        expect(p, contains('Запрещены: markdown'));
      }
    });

    test('the everyday one is honest about Kazakh paperwork going stale', () {
      expect(systemPromptFor(AnswerMode.everyday), contains('egov.kz'));
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

    test('a medical question gets the strict prompt', () async {
      final service = GeminiAssistantService(
        client: client(),
        endpoint: endpoint,
      );
      final reply =
          await service.ask(question: 'температура 38', ageMonths: 6)
              as AssistantAnswer;

      expect(sent!['system'], systemPrompt);
      expect(reply.mode, AnswerMode.medical);
      expect(reply.isFromGeneralKnowledge, isFalse);
      expect(reply.sources, isNotEmpty);
    });

    test('an everyday question gets the wider prompt', () async {
      final service = GeminiAssistantService(
        client: client(),
        endpoint: endpoint,
      );
      final reply =
          await service.ask(
                question: 'как встать в очередь в садик',
                ageMonths: 24,
              )
              as AssistantAnswer;

      expect(sent!['system'], systemPromptFor(AnswerMode.everyday));
      expect(reply.isFromGeneralKnowledge, isTrue);
    });

    test('no answer is dressed in unrelated sources', () async {
      // The age fallback used to attach four paediatric articles to any
      // question the search could not place — which the screen then listed
      // underneath as where the answer came from. It was not.
      const unplaceable = 'абракадабра непонятная';
      final service = GeminiAssistantService(
        client: client(),
        endpoint: endpoint,
      );
      final reply =
          await service.ask(question: unplaceable, ageMonths: 3)
              as AssistantAnswer;

      expect(reply.sources, isEmpty);
    });

    test('a health question the base misses is answered, not refused', () async {
      // «Остались заготовленные вопросы и ответы»: forty-seven articles cannot
      // cover what parents ask, and everything outside them used to come back
      // as «В моей базе нет ответа на этот вопрос».
      const outside = 'ребёнок скрипит зубами ночью';
      expect(modeFor(outside), AnswerMode.medical, reason: 'a health topic');

      final service = GeminiAssistantService(
        client: client(),
        endpoint: endpoint,
      );
      final reply =
          await service.ask(question: outside, ageMonths: 6)
              as AssistantAnswer;

      expect(reply.mode, AnswerMode.generalHealth);
      expect(sent!['system'], systemPromptFor(AnswerMode.generalHealth));
      // Said out loud on screen rather than passed off as vetted.
      expect(reply.isFromGeneralKnowledge, isTrue);
    });

    test('but a question the base does cover is still answered from it', () async {
      final service = GeminiAssistantService(
        client: client(),
        endpoint: endpoint,
      );
      final reply =
          await service.ask(question: 'температура 38', ageMonths: 6)
              as AssistantAnswer;

      expect(reply.mode, AnswerMode.medical);
      expect(sent!['system'], systemPrompt);
      expect(reply.sources, isNotEmpty);
    });

    test('the wider mode still forbids what can hurt somebody', () {
      final p = systemPromptFor(AnswerMode.generalHealth);
      expect(p, contains('Ставить диагноз'));
      expect(p, contains('дозировк'));
      expect(p, contains('педиатру'));
      // And it has to admit where it came from, in the answer itself.
      expect(p, contains('ПО ЭТОМУ ВОПРОСУ В БАЗЕ НИЧЕГО НЕ НАШЛОСЬ'));
      expect(p, contains('отвечаю общими'));
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

      // Everyday words in the sentence change nothing: red flags are caught
      // deterministically, before the topic gate is even consulted.
      final reply = await service.ask(
        question: 'в садике он упал с горки и не реагирует',
      );
      expect(reply, isA<AssistantEmergency>());
      expect(calls, 0);
    });
  });
}
