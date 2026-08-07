import 'dart:convert';

import 'package:child_health_tracker/ai/assistant_service.dart';
import 'package:child_health_tracker/ai/child_snapshot.dart';
import 'package:child_health_tracker/ai/conversation.dart';
import 'package:child_health_tracker/ai/prompt.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/models/reminder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Step A of the assistant upgrade: it remembers the conversation, and it is
/// told what the app already knows about the child.
///
/// Before this, every question travelled alone with a name, an age and a
/// gender — while the screen it was typed on showed six feeds, a nap and a
/// temperature the model was never given.
void main() {
  const endpoint = 'https://example.invalid/ai';
  final now = DateTime(2026, 8, 7, 16, 30);

  final child = Child(
    id: 'demo',
    parentUid: 'u',
    name: 'Айгерим',
    birthDate: DateTime(2026, 2, 7),
    gender: Gender.female,
  );

  DevelopmentLog log(
    LogType type, {
    required Duration ago,
    int? minutes,
    int? wakings,
    NappyKind? nappy,
    double? weight,
    double? height,
    double? temperature,
    Severity? severity,
  }) => DevelopmentLog(
    id: '$type$ago$minutes$weight$temperature',
    childId: 'demo',
    date: now.subtract(ago),
    type: type,
    title: 'x',
    durationMinutes: minutes,
    nightWakings: wakings,
    nappyKind: nappy,
    severity: severity,
    metrics: Metrics(
      weightKg: weight,
      heightCm: height,
      temperatureC: temperature,
    ),
  );

  group('child snapshot', () {
    test('opens with who the child is', () {
      final block = childSnapshot(child: child, now: now);
      expect(block, contains('Айгерим'));
      expect(block, contains('девочка'));
      expect(block, contains('6 мес.'));
      expect(block, contains('07.02.2026'));
    });

    test('says plainly when nothing has been recorded', () {
      final block = childSnapshot(child: child, now: now);
      expect(block, contains('пока нет'));
    });

    test('carries the latest measurement with its WHO percentile', () {
      final block = childSnapshot(
        child: child,
        logs: [
          log(LogType.measurement, ago: const Duration(days: 40), weight: 5.0),
          log(LogType.measurement, ago: const Duration(days: 5), weight: 7.4,
              height: 66.0),
        ],
        now: now,
      );

      expect(block, contains('Вес: 7.4 кг'));
      expect(block, contains('Рост: 66.0 см'));
      expect(block, contains('перцентиль ВОЗ'));
      // The older weight was superseded, not averaged in.
      expect(block, isNot(contains('5.0 кг')));
    });

    test('counts today: feeds, sleep and nappies', () {
      final block = childSnapshot(
        child: child,
        logs: [
          for (var i = 1; i <= 6; i++)
            log(LogType.feeding, ago: Duration(hours: i * 2)),
          log(LogType.sleep, ago: const Duration(hours: 3), minutes: 95),
          log(LogType.nappy, ago: const Duration(hours: 1),
              nappy: NappyKind.wet),
          log(LogType.nappy, ago: const Duration(hours: 4),
              nappy: NappyKind.both),
        ],
        now: now,
      );

      expect(block, contains('кормлений 6'));
      expect(block, contains('1 ч 35 мин'));
      expect(block, contains('мокрых 2'));
      expect(block, contains('со стулом 1'));
    });

    test('reports the day\'s highest temperature, not only the last', () {
      final block = childSnapshot(
        child: child,
        logs: [
          log(LogType.illness, ago: const Duration(hours: 5),
              temperature: 39.1),
          log(LogType.illness, ago: const Duration(hours: 1),
              temperature: 37.4),
        ],
        now: now,
      );

      expect(block, contains('37.4 °C'));
      expect(block, contains('максимум за день 39.1 °C'));
    });

    test('averages the week over the days actually written down', () {
      // Two days of entries, not seven. Averaging over seven would accuse a
      // mother who started the diary on Friday of underfeeding since Monday.
      final block = childSnapshot(
        child: child,
        logs: [
          for (var i = 0; i < 8; i++)
            log(LogType.feeding, ago: Duration(hours: i + 1)),
          for (var i = 0; i < 8; i++)
            log(LogType.feeding, ago: Duration(hours: 24 + i)),
        ],
        now: now,
      );

      expect(block, contains('кормлений 16'));
      expect(block, contains('≈8 в день'));
    });

    test('counts sick days and names the last one', () {
      final block = childSnapshot(
        child: child,
        logs: [
          log(LogType.illness, ago: const Duration(days: 10),
              severity: Severity.mild),
          log(LogType.illness, ago: const Duration(days: 9),
              severity: Severity.moderate),
          // Outside the window: must not be counted.
          log(LogType.illness, ago: const Duration(days: 90),
              severity: Severity.severe),
        ],
        now: now,
      );

      expect(block, contains('2 дн.'));
      expect(block, contains('29.07.2026'));
      expect(block, isNot(contains('тяжёлая')));
    });

    test('names the next vaccinations and the open reminders', () {
      final block = childSnapshot(
        child: child,
        reminders: [
          Reminder(
            id: '1',
            childId: 'demo',
            type: ReminderType.vaccination,
            title: 'Пентавакцина — третья доза',
            scheduledTime: now.add(const Duration(days: 10)),
          ),
          Reminder(
            id: '2',
            childId: 'demo',
            type: ReminderType.appointment,
            title: 'Приём педиатра',
            scheduledTime: now.add(const Duration(days: 2)),
          ),
          Reminder(
            id: '3',
            childId: 'demo',
            type: ReminderType.vaccination,
            title: 'Уже сделана',
            scheduledTime: now.add(const Duration(days: 30)),
            isCompleted: true,
          ),
        ],
        now: now,
      );

      expect(block, contains('Пентавакцина — третья доза'));
      expect(block, contains('Приём педиатра'));
      expect(block, isNot(contains('Уже сделана')));
    });

    test('stays short enough to leave room for the articles', () {
      final block = childSnapshot(
        child: child,
        logs: [
          for (var i = 0; i < 400; i++)
            log(LogType.feeding, ago: Duration(minutes: i * 7)),
        ],
        now: now,
      );
      expect(block.length, lessThanOrEqualTo(snapshotMaxChars + 1));
    });
  });

  group('conversation history', () {
    test('keeps only the last three exchanges', () {
      final turns = [
        for (var i = 0; i < 10; i++)
          i.isEven ? ChatTurn.parent('вопрос $i') : ChatTurn.assistant('ответ $i'),
      ];
      final trimmed = trimHistory(turns);

      expect(trimmed.length, lessThanOrEqualTo(maxHistoryTurns));
      expect(trimmed.last.text, 'ответ 9');
    });

    test('always begins with something the parent said', () {
      // Gemini rejects a conversation that opens on a model turn.
      final trimmed = trimHistory([
        ChatTurn.assistant('ответ без вопроса'),
        ChatTurn.parent('вопрос'),
      ]);
      expect(trimmed.first.isParent, isTrue);
    });

    test('shortens a message nobody should have sent', () {
      final trimmed = trimHistory([ChatTurn.parent('а' * 5000)]);
      expect(trimmed.single.text.length, maxHistoryTurnChars + 1);
    });

    test('drops empty turns', () {
      expect(trimHistory([ChatTurn.parent('   ')]), isEmpty);
    });
  });

  group('what actually goes over the wire', () {
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

    test('the thread travels with the question', () async {
      final service = GeminiAssistantService(
        client: client(),
        endpoint: endpoint,
      );

      await service.ask(
        question: 'а если не поможет',
        ageMonths: 6,
        history: [
          ChatTurn.parent('температура 38 что делать'),
          ChatTurn.assistant('Дайте жаропонижающее по весу.'),
        ],
      );

      final history = sent!['history'] as List;
      expect(history, hasLength(2));
      expect(history.first['role'], 'user');
      expect(history.last['role'], 'model');
      expect(history.last['text'], contains('жаропонижающее'));
      // The current question is the prompt, never a history entry.
      expect(sent!['prompt'], contains('а если не поможет'));
    });

    test('a first question carries no history field at all', () async {
      final service = GeminiAssistantService(
        client: client(),
        endpoint: endpoint,
      );
      await service.ask(question: 'когда вводить прикорм', ageMonths: 6);
      expect(sent!.containsKey('history'), isFalse);
    });

    test('the child data reaches the prompt', () async {
      final service = GeminiAssistantService(
        client: client(),
        endpoint: endpoint,
      );

      await service.ask(
        question: 'достаточно ли молока',
        ageMonths: 6,
        childContext: childSnapshot(
          child: child,
          logs: [
            for (var i = 1; i <= 6; i++)
              log(LogType.feeding, ago: Duration(hours: i)),
          ],
          now: now,
        ),
      );

      final prompt = sent!['prompt'] as String;
      expect(prompt, contains('КОНТЕКСТ РЕБЁНКА'));
      expect(prompt, contains('кормлений 6'));
      expect(prompt, contains('БАЗА ЗНАНИЙ'));
    });

    test('a red flag still stops everything, history or not', () async {
      var calls = 0;
      final service = GeminiAssistantService(
        client: MockClient((_) async {
          calls++;
          return http.Response('{}', 200);
        }),
        endpoint: endpoint,
      );

      final reply = await service.ask(
        question: 'а теперь она не дышит',
        history: [ChatTurn.parent('температура 38'),
                  ChatTurn.assistant('Дайте жаропонижающее.')],
      );

      expect(reply, isA<AssistantEmergency>());
      expect(calls, 0);
    });
  });

  group('system prompt', () {
    test('tells the model the child data is fact, not advice', () {
      expect(systemPrompt, contains('КОНТЕКСТ РЕБЁНКА'));
      expect(systemPrompt, contains('Не ставь по ним диагноз'));
    });

    test('forbids treating its own past answers as a source', () {
      expect(systemPrompt, contains('ХОД РАЗГОВОРА'));
      expect(systemPrompt, contains('базой знаний не считай'));
    });
  });
}
