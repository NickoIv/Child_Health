/// What the assistant is allowed to ask the app to do.
///
/// The model never touches the data. It proposes one action, the parent reads
/// exactly what will happen and taps once, and only then does the app write
/// anything — the same line the voice input is built around, for the same
/// reason: a microphone that wrote a fever into a record because a room was
/// noisy would be worse than no microphone, and a model that logged a feed
/// because it misread a sentence is the same failure with better grammar.
///
/// Two boundaries hold here, and neither depends on the model behaving:
///
/// 1. **The list is closed.** Anything that is not one of the shapes below is
///    dropped on the floor. Deleting entries, editing the medical record,
///    inviting family and changing account settings have no representation at
///    all — there is nothing for a persuaded model to emit.
/// 2. **Every value is re-checked here.** A temperature outside 34–43, a
///    reminder a decade out, a screen that is not on the list, an article id
///    that does not exist: the action is discarded and the parent still gets
///    the answer. An invalid proposal is never a broken screen.
///
/// Why a tagged line rather than the API's own function calling: this parses
/// the same way whatever the endpoint does, it is testable without a live
/// model, and the last time this app depended on a Gemini request field it
/// came back 400 INVALID_ARGUMENT and took the assistant down with it.
library;

import 'dart:convert';

import '../knowledge/knowledge_base.dart';
import '../models/development_log.dart';
import '../models/reminder.dart';

/// What the model writes to propose an action, on its own last line.
const actionMarker = '[ДЕЙСТВИЕ]';

/// Screens the assistant may open. Everything reachable from the navigation
/// except settings, which is the account rather than the child.
const allowedScreens = <String>[
  '/',
  '/diary',
  '/growth',
  '/illness',
  '/medical',
  '/reminders',
  '/children',
  '/assistant',
  '/assistant/triage',
];

/// Marks an entry the assistant proposed and the parent confirmed.
///
/// A tag rather than a sentence in the description: it is language-free, so
/// it cannot leak Russian onto a Kazakh diary, and it survives being read
/// back by a version of the app that has never heard of it.
const assistantTag = 'assistant';

/// One thing the assistant proposes to do.
sealed class AssistantAction {
  const AssistantAction();
}

class LogFeedingAction extends AssistantAction {
  const LogFeedingAction({this.minutes, this.side});

  final int? minutes;
  final FeedingSide? side;
}

class LogSleepAction extends AssistantAction {
  const LogSleepAction({required this.minutes});

  final int minutes;
}

class LogNappyAction extends AssistantAction {
  const LogNappyAction({required this.kind});

  final NappyKind kind;
}

class LogTemperatureAction extends AssistantAction {
  const LogTemperatureAction({required this.celsius});

  final double celsius;
}

/// Weight, height, or both.
///
/// The gap this closes was the widest of them: the app plots growth against
/// the WHO standard on its own screen, and «записала вес 5 200» was the one
/// sentence the assistant could not act on. A measurement is also the entry a
/// parent is most likely to be holding a baby for.
class LogGrowthAction extends AssistantAction {
  const LogGrowthAction({this.weightKg, this.heightCm});

  final double? weightKg;
  final double? heightCm;

  bool get isEmpty => weightKg == null && heightCm == null;
}

/// A spoonful of something, by name.
///
/// The name matters more than the fact: it is what the three-day watch and the
/// allergen table in the medical card are built on, and what the assistant
/// reads back when she asks «от чего его обсыпало».
class LogSolidAction extends AssistantAction {
  const LogSolidAction({required this.food, this.minutes});

  final String food;
  final int? minutes;
}

/// Milk expressed. A note, never a feed — counting it in the day's tally
/// would flatter a mother checking herself against «8-12 кормлений».
class LogPumpingAction extends AssistantAction {
  const LogPumpingAction({required this.milkMl});

  final int milkMl;
}

class CreateReminderAction extends AssistantAction {
  const CreateReminderAction({
    required this.title,
    required this.type,
    required this.at,
  });

  final String title;

  /// Never [ReminderType.vaccination]: the immunisation plan is generated
  /// from the national calendar, and a made-up dose sitting among real ones
  /// is a lie a parent would have no way to spot.
  final ReminderType type;

  final DateTime at;
}

class OpenScreenAction extends AssistantAction {
  const OpenScreenAction({required this.path});

  final String path;
}

class OpenArticleAction extends AssistantAction {
  const OpenArticleAction({required this.articleId});

  final String articleId;
}

/// Opens the export sheet, where the parent still picks the period. The model
/// proposes the report, it does not decide what goes in it.
class BuildReportAction extends AssistantAction {
  const BuildReportAction();
}

/// The answer split into what the parent reads and what the app is asked to do.
class ParsedReply {
  const ParsedReply({required this.text, this.action});

  final String text;
  final AssistantAction? action;
}

/// Pulls the action line out of a raw model reply.
///
/// The marker and its JSON are removed from the text whatever happens, valid
/// or not: a parent must never be shown the machinery. [now] is injectable so
/// a reminder's date is testable without racing the clock.
ParsedReply parseAssistantReply(String raw, {DateTime? now}) {
  final start = raw.indexOf(actionMarker);
  if (start < 0) return ParsedReply(text: raw.trim());

  final open = raw.indexOf('{', start);
  final end = open < 0 ? -1 : _endOfObject(raw, open);

  // Everything from the marker to the end of the object goes, and if the
  // object never closed — a truncated reply — the rest of the line goes too.
  final cut = end > 0 ? end : _endOfLine(raw, start);
  final text = (raw.substring(0, start) + raw.substring(cut))
      .replaceAll(actionMarker, '')
      .trim();

  if (end <= 0) return ParsedReply(text: text);

  return ParsedReply(
    text: text,
    action: _decode(raw.substring(open, end), now ?? DateTime.now()),
  );
}

/// Index just past the object opening at [open], or -1 if it never closes.
/// Braces inside strings do not count, and neither does an escaped quote.
int _endOfObject(String s, int open) {
  var depth = 0;
  var inString = false;
  var escaped = false;

  for (var i = open; i < s.length; i++) {
    final c = s[i];
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (c == r'\') {
        escaped = true;
      } else if (c == '"') {
        inString = false;
      }
      continue;
    }
    if (c == '"') {
      inString = true;
    } else if (c == '{') {
      depth++;
    } else if (c == '}') {
      depth--;
      if (depth == 0) return i + 1;
    }
  }
  return -1;
}

int _endOfLine(String s, int from) {
  final nl = s.indexOf('\n', from);
  return nl < 0 ? s.length : nl;
}

/// Everything below returns null rather than throwing. A malformed proposal
/// costs the parent nothing; an exception would cost her the answer.
AssistantAction? _decode(String json, DateTime now) {
  Map<String, dynamic> decoded;
  try {
    final value = jsonDecode(json);
    if (value is! Map<String, dynamic>) return null;
    decoded = value;
  } on FormatException {
    return null;
  }

  final tool = decoded['tool'];
  if (tool is! String) return null;
  final args = decoded['args'] is Map
      ? (decoded['args'] as Map).cast<String, dynamic>()
      : const <String, dynamic>{};

  return switch (tool) {
    'log_feeding' => LogFeedingAction(
      minutes: _int(args['minutes'], 1, 240),
      side: FeedingSide.fromCode(args['side'] as String?),
    ),
    'log_sleep' => switch (_int(args['minutes'], 1, 1440)) {
      final int minutes => LogSleepAction(minutes: minutes),
      _ => null,
    },
    'log_nappy' => LogNappyAction(
      kind: NappyKind.fromCode(args['kind'] as String?) ?? NappyKind.wet,
    ),
    // The one number in this app that must never be a typo waved through:
    // the same 34–43 the voice input enforces, and no default.
    'log_temperature' => switch (_double(args['celsius'], 34, 43)) {
      final double celsius => LogTemperatureAction(celsius: celsius),
      _ => null,
    },
    // Ranges wide enough for any child this app will meet and narrow enough
    // that a misheard «пятьдесят два» cannot land as a plausible weight.
    'log_growth' => switch (LogGrowthAction(
      weightKg: _double(args['weight_kg'], 0.5, 60),
      heightCm: _double(args['height_cm'], 20, 150),
    )) {
      final LogGrowthAction a when !a.isEmpty => a,
      _ => null,
    },
    'log_solid' => switch ((args['food'] as String? ?? '').trim()) {
      final String food when food.isNotEmpty && food.length <= 60 =>
        LogSolidAction(food: food, minutes: _int(args['minutes'], 1, 240)),
      _ => null,
    },
    'log_pumping' => switch (_int(args['milk_ml'], 1, 1000)) {
      final int ml => LogPumpingAction(milkMl: ml),
      _ => null,
    },
    'create_reminder' => _reminder(args, now),
    'open_screen' => switch (args['path']) {
      final String path when allowedScreens.contains(path) => OpenScreenAction(
        path: path,
      ),
      _ => null,
    },
    'open_article' => switch (args['id']) {
      final String id when articleById(id) != null => OpenArticleAction(
        articleId: id,
      ),
      _ => null,
    },
    'build_report' => const BuildReportAction(),
    _ => null,
  };
}

CreateReminderAction? _reminder(Map<String, dynamic> args, DateTime now) {
  final title = (args['title'] as String? ?? '').trim();
  if (title.isEmpty) return null;

  // Two years out at the most. Anything further is a misread date rather than
  // a plan, and a notification scheduled for 2049 is never seen again.
  final days = _int(args['in_days'], 0, 730);
  if (days == null) return null;

  final type = switch (args['type']) {
    'medication' => ReminderType.medication,
    _ => ReminderType.appointment,
  };

  final clock = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(
    (args['time'] as String? ?? '').trim(),
  );
  final hour = _int(clock?.group(1), 0, 23) ?? 9;
  final minute = _int(clock?.group(2), 0, 59) ?? 0;

  final day = DateTime(now.year, now.month, now.day).add(Duration(days: days));
  return CreateReminderAction(
    title: title.length <= 80 ? title : '${title.substring(0, 79)}…',
    type: type,
    at: DateTime(day.year, day.month, day.day, hour, minute),
  );
}

int? _int(Object? value, int min, int max) {
  final n = switch (value) {
    final int v => v,
    final num v => v.round(),
    final String v => int.tryParse(v.trim()),
    _ => null,
  };
  if (n == null || n < min || n > max) return null;
  return n;
}

double? _double(Object? value, double min, double max) {
  final n = switch (value) {
    final num v => v.toDouble(),
    final String v => double.tryParse(v.trim().replaceAll(',', '.')),
    _ => null,
  };
  if (n == null || n < min || n > max) return null;
  return n;
}

/// The entry a confirmed action becomes, or null for an action that writes
/// nothing.
///
/// Deliberately the same shapes the quick sheets and the voice input already
/// write — same types, same titles, same fields — so an entry the assistant
/// proposed is one record on one timeline, and every count in the app keeps
/// working without knowing where it came from.
DevelopmentLog? assistantDraft(
  AssistantAction action, {
  required String childId,
  required DateTime at,
}) {
  DevelopmentLog build(
    LogType type,
    String title, {
    Metrics metrics = const Metrics(),
    FeedingSide? side,
    NappyKind? nappy,
    int? minutes,
    Severity? severity,
    String? food,
    int? milkMl,
  }) => DevelopmentLog(
    id: '',
    childId: childId,
    date: at,
    type: type,
    // Russian, like every stored title: these are documents read back years
    // later, and what a parent sees is looked up from the code.
    title: title,
    metrics: metrics,
    tags: const [assistantTag],
    feedingSide: side,
    nappyKind: nappy,
    durationMinutes: minutes,
    severity: severity,
    food: food,
    milkMl: milkMl,
  );

  return switch (action) {
    LogFeedingAction(:final minutes, :final side) => build(
      LogType.feeding,
      LogType.feeding.label,
      side: side,
      minutes: minutes,
    ),
    LogSleepAction(:final minutes) => build(
      LogType.sleep,
      LogType.sleep.label,
      minutes: minutes,
    ),
    LogNappyAction(:final kind) => build(
      LogType.nappy,
      LogType.nappy.label,
      nappy: kind,
    ),
    // The same threshold the temperature sheet uses, so a reading the
    // assistant wrote lands in the illness history exactly where a typed one
    // does.
    LogTemperatureAction(:final celsius) => build(
      celsius >= 38.0 ? LogType.illness : LogType.measurement,
      '${LogTitles.temperature} ${celsius.toStringAsFixed(1)} °C',
      metrics: Metrics(temperatureC: celsius),
      severity: celsius >= 39.0
          ? Severity.severe
          : celsius >= 38.0
          ? Severity.moderate
          : null,
    ),
    // A measurement, which is what the growth chart reads. Both figures on one
    // entry when both were said: two records dated a second apart would draw
    // two points on a chart for one moment on a scale.
    LogGrowthAction(:final weightKg, :final heightCm) => build(
      LogType.measurement,
      LogType.measurement.label,
      metrics: Metrics(weightKg: weightKg, heightCm: heightCm),
    ),
    // A feed with a name on it — the same shape the «Прикорм» step writes, so
    // the three-day watch and the allergen table pick it up without knowing
    // it was spoken rather than tapped.
    LogSolidAction(:final food, :final minutes) => build(
      LogType.feeding,
      LogType.feeding.label,
      side: FeedingSide.solid,
      minutes: minutes,
      food: food,
    ),
    LogPumpingAction(:final milkMl) => build(
      LogType.note,
      LogTitles.pumping,
      milkMl: milkMl,
    ),
    _ => null,
  };
}

/// And the reminder a confirmed [CreateReminderAction] becomes.
Reminder assistantReminder(
  CreateReminderAction action, {
  required String childId,
}) => Reminder(
  id: '',
  childId: childId,
  type: action.type,
  title: action.title,
  scheduledTime: action.at,
);
