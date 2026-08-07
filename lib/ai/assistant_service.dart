import 'dart:convert';

import 'package:http/http.dart' as http;

import '../knowledge/article.dart';
import '../knowledge/triage.dart';
import 'actions.dart';
import 'ai_config.dart';
import 'conversation.dart';
import 'prompt.dart';
import 'rag.dart';
import 'topics.dart';

/// What the assistant produced.
sealed class AssistantReply {
  const AssistantReply();
}

/// A normal answer, with the articles it was built from.
class AssistantAnswer extends AssistantReply {
  const AssistantAnswer({
    required this.text,
    required this.sources,
    this.action,
    this.mode = AnswerMode.medical,
  });

  final String text;
  final List<KbArticle> sources;

  /// Which rules the answer was produced under. An everyday answer may draw on
  /// the model's own knowledge, and the screen says so rather than letting it
  /// pass for something the app has vetted.
  final AnswerMode mode;

  /// True whenever the answer came from the model rather than from a vetted
  /// article — an everyday question, or a health one the base did not cover.
  bool get isFromGeneralKnowledge => mode != AnswerMode.medical;

  /// What the model proposes the app should do about it, if anything. Nothing
  /// happens until the parent confirms — see `ai/actions.dart`.
  final AssistantAction? action;
}

/// The question described a red flag. The model was never called: this is a
/// hard stop, decided by the deterministic triage rules.
class AssistantEmergency extends AssistantReply {
  const AssistantEmergency({required this.matched});

  /// Red-flag phrases recognised in the question.
  final List<String> matched;
}

/// The assistant is switched off or unreachable.
class AssistantUnavailable extends AssistantReply {
  const AssistantUnavailable(this.reason, {this.isConfigurationIssue = false});

  final String reason;
  final bool isConfigurationIssue;
}

abstract class AssistantService {
  bool get isConfigured;

  /// [history] is the thread so far, oldest first, excluding [question].
  Future<AssistantReply> ask({
    required String question,
    int? ageMonths,
    String? childContext,
    List<ChatTurn> history = const [],
  });
}

/// Word stems that must never reach a language model.
///
/// If a parent types any of these, the only correct response is the emergency
/// screen. Asking a model to weigh in — even a well-prompted one — adds a
/// chance of a reassuring answer to a question where reassurance can kill.
///
/// Stems, not whole words: Russian verbs inflect for gender, and a mother
/// writing about her daughter types «подавилась», not «подавился». Matching
/// exact forms silently missed half the cases.
///
/// This filter is deliberately over-eager. A false alarm costs a parent one
/// unnecessary fright; a miss costs something that cannot be refunded. When in
/// doubt, a stem goes in.
const _emergencyStems = <String>[
  'не дышит',
  'не дышал',
  'перестал дышать',
  'перестала дышать',
  'задыхает',
  'посинел',
  'синеют губы',
  'синие губы',
  'синеет',
  'судорог',
  'сознание',
  'не могу разбудить',
  'не просыпает',
  'не реагирует',
  'обмяк',
  'подавил',
  'поперхнул',
  'батарейк',
  'проглотил магнит',
  'инородное тело',
  'выпал из',
  'выпала из',
  'упал с',
  'упала с',
  // Reflexive verbs put -ся/-сь between the stem and the noun, so «ударил
  // голов» never matches «ударился головой». The forms are listed out.
  'ударился голов',
  'ударилась голов',
  'стукнулся голов',
  'стукнулась голов',
  'упал головой',
  'упала головой',
  'травма голов',
  'ушиб голов',
  'сыпь не бледнеет',
  'не бледнеет',
  'кровь в стуле',
  'кровь в рвот',
  'рвота с кровью',
  'рвёт кровью',
  'зелёная рвот',
  'зеленая рвот',
  'рвота зелён',
  'рвота зелен',
  'обварил',
  'ошпарил',
  'ожог',
  'отравил',
  'наглотал',
  'выпил таблет',
  'съел таблет',
  'проглотил таблет',
  'не мочился',
  'запал родничок',
  'выбухает родничок',
];

/// Red-flag stems found in [question].
///
/// `ё` is folded to `е` because parents type both, and a filter that misses
/// «зеленая рвота» because the base spells it «зелёная» is worse than useless.
List<String> detectEmergencyPhrases(String question) {
  final q = question.toLowerCase().replaceAll('ё', 'е');
  return _emergencyStems
      .where((stem) => q.contains(stem.replaceAll('ё', 'е')))
      .toList();
}

/// Assistant backed by Gemini, reached through the Cloudflare Worker proxy.
class GeminiAssistantService implements AssistantService {
  /// [endpoint] defaults to the compile-time [AiConfig.proxyUrl]; tests pass
  /// it explicitly, since a --dart-define cannot be changed per test case.
  GeminiAssistantService({http.Client? client, String? endpoint})
    : _client = client ?? http.Client(),
      _endpoint = endpoint ?? AiConfig.proxyUrl;

  final http.Client _client;
  final String _endpoint;

  @override
  bool get isConfigured => _endpoint.isNotEmpty;

  @override
  Future<AssistantReply> ask({
    required String question,
    int? ageMonths,
    String? childContext,
    List<ChatTurn> history = const [],
  }) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) {
      return const AssistantUnavailable('Пустой вопрос');
    }

    // Gate first, model second. This ordering is the whole safety design:
    // an emergency never depends on what a model decides to say.
    final matched = detectEmergencyPhrases(trimmed);
    if (matched.isNotEmpty) {
      return AssistantEmergency(matched: matched);
    }

    if (!isConfigured) {
      return const AssistantUnavailable(
        'Помощник не подключён: не задан адрес прокси AI_PROXY_URL.',
        isConfigurationIssue: true,
      );
    }

    // Decided here, in Dart, before anything is sent: whether this question is
    // answered strictly from the articles or may draw on what the model knows.
    // See `ai/topics.dart` — silence means health.
    final topic = modeFor(trimmed);

    // No age fallback any more, in either direction. It was there so a health
    // question was never left without material, but what it actually did was
    // staple four unrelated articles to the prompt — which the strict rules
    // then had to refuse from, and which the screen listed underneath as the
    // «источники» of an answer they had nothing to do with. An empty result is
    // now allowed to mean what it says.
    final context = retrieveFor(trimmed, ageMonths: ageMonths,
        ageFallback: false);

    // Three ways to answer, and which one this is depends on what retrieval
    // found rather than on the question alone: a health question the base
    // covers is answered from the base, and one it does not is answered
    // honestly instead of not at all.
    final mode = switch (topic) {
      AnswerMode.everyday => AnswerMode.everyday,
      _ when context.isEmpty => AnswerMode.generalHealth,
      _ => AnswerMode.medical,
    };
    // Retrieval runs on this question alone, on purpose. Searching the whole
    // thread drags the articles of the previous topic into the answer to the
    // next one, and the base is the only thing the model may answer from.
    final past = trimHistory(history);
    final body = jsonEncode({
      'system': systemPromptFor(mode),
      'prompt': buildUserPrompt(
        question: trimmed,
        knowledgeBlock: context.promptBlock,
        childContext: childContext,
      ),
      if (past.isNotEmpty) 'history': [for (final t in past) t.toJson()],
    });

    try {
      var response = await _post(body);

      // A freshly deployed Worker answers 502 for a few seconds while the new
      // version propagates across the edge, and upstream hiccups look the
      // same. One quiet retry turns that into a slightly slower answer
      // instead of an error message the parent has to interpret.
      if (response.statusCode == 502) {
        await Future<void>.delayed(const Duration(seconds: 2));
        response = await _post(body);
      }

      if (response.statusCode == 429) {
        return const AssistantUnavailable(
          'Слишком много запросов. Попробуйте через минуту.',
        );
      }
      if (response.statusCode != 200) {
        return AssistantUnavailable(
          'Сервис помощника недоступен (код ${response.statusCode}).',
        );
      }

      final decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final raw = (decoded['text'] as String? ?? '').trim();

      // The action line is stripped here, so nothing downstream can put the
      // machinery on screen — including the failure case where the JSON was
      // malformed and there is no action to show.
      final parsed = parseAssistantReply(raw);
      if (parsed.text.isEmpty) {
        return const AssistantUnavailable('Помощник вернул пустой ответ.');
      }

      return AssistantAnswer(
        text: parsed.text,
        sources: context.articles,
        action: parsed.action,
        mode: mode,
      );
    } on Exception catch (e) {
      return AssistantUnavailable('Не удалось получить ответ: $e');
    }
  }

  Future<http.Response> _post(String body) => _client
      .post(
        Uri.parse(_endpoint),
        headers: const {'Content-Type': 'application/json'},
        body: body,
      )
      .timeout(AiConfig.timeout);
}

/// Used when the build has no proxy configured, and in tests.
class DisabledAssistantService implements AssistantService {
  const DisabledAssistantService();

  @override
  bool get isConfigured => false;

  @override
  Future<AssistantReply> ask({
    required String question,
    int? ageMonths,
    String? childContext,
    List<ChatTurn> history = const [],
  }) async {
    final matched = detectEmergencyPhrases(question);
    if (matched.isNotEmpty) return AssistantEmergency(matched: matched);
    return const AssistantUnavailable(
      'Помощник с ИИ пока не подключён. База знаний и проверка тревожных '
      'признаков работают без него.',
      isConfigurationIssue: true,
    );
  }
}

/// Emergency copy shown when the gate fires. Deliberately identical wording to
/// the triage screen's top level, so the app never contradicts itself.
String get emergencyGateAdvice => TriageLevel.emergency.advice;
