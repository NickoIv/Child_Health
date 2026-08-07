import '../core/analytics/daily_digest.dart';
import '../l10n/app_localizations.dart';
import '../models/development_log.dart';
import '../models/json.dart';

/// What the chat offers before a word has been typed.
///
/// The five chips this replaces were the same five sentences for every parent
/// on every day — «не вижу умного ИИ, только заготовленные вопросы» was a fair
/// reading of them, because a fixed list is exactly what they were. These are
/// drawn from the entries already in the diary: a reading taken this morning, a
/// night with five wakings in it, the age the child actually is.
///
/// It is still arithmetic, not a model — the assistant has not been asked
/// anything yet. But it is arithmetic on *this* child, and each suggestion
/// carries the fact it came from, so what the app knows is visible on screen
/// rather than asserted in a prompt nobody can read.
enum AskTopic {
  /// A reading was taken today and it was high.
  temperatureToday,

  /// Last night had more wakings than a night usually does.
  hardNight,

  /// A day and more with no nappy written down.
  quietNappies,

  /// By age: what a newborn's feeding looks like.
  newbornFeeding,

  /// By age: naps and night sleep at a few months.
  sleepNeeds,

  /// By age: starting solids.
  solids,

  /// By age: what children this old are usually doing.
  milestones,

  /// The general list, for a child with nothing recorded yet.
  ///
  /// Three, and deliberately not three medical ones: the assistant answers
  /// anything now, and a panel that only ever proposes fevers and feeds is how
  /// a parent concludes it does not.
  commonHealth,
  commonEveryday,
  commonAnything,
}

/// A question, and the fact behind it.
class SuggestedQuestion {
  const SuggestedQuestion(this.topic, {this.temperature, this.wakings});

  final AskTopic topic;

  /// The reading the suggestion was drawn from, where it was drawn from one.
  final double? temperature;

  /// The wakings it was drawn from, likewise.
  final int? wakings;
}

/// Above this a reading is worth a question. Deliberately below the 38.0 the
/// app treats as a fever elsewhere: this only decides what to *offer*, and a
/// parent watching 37.6 climb is the one most likely to want to ask.
const _askAboveC = 37.5;

/// A nappy going unrecorded this long is worth a question rather than a nudge —
/// the dashboard already asks her to write one down after four hours.
const _quietNappyHours = 24;

/// Three at most. A list of suggestions long enough to scroll is a menu, and
/// the field underneath it is the thing she actually came to use.
const maxSuggestions = 3;

/// What to offer this parent, now, most specific first.
List<SuggestedQuestion> suggestedQuestions({
  required List<DevelopmentLog> logs,
  required DateTime now,
  int? ageMonths,
}) {
  final picked = <SuggestedQuestion>[];

  final temperature = _highestToday(logs, now);
  if (temperature != null && temperature >= _askAboveC) {
    picked.add(
      SuggestedQuestion(AskTopic.temperatureToday, temperature: temperature),
    );
  }

  final wakings = _lastNightWakings(logs, now);
  if (wakings != null && wakings >= DigestThresholds.hardNightWakings) {
    picked.add(SuggestedQuestion(AskTopic.hardNight, wakings: wakings));
  }

  if (_nappiesAreQuiet(logs, now)) {
    picked.add(const SuggestedQuestion(AskTopic.quietNappies));
  }

  if (ageMonths != null) {
    picked.add(SuggestedQuestion(_byAge(ageMonths)));
  }

  // Whatever is left over goes to the general list, so the panel is never
  // half-empty on a child whose diary has just been started.
  for (final topic in const [
    AskTopic.commonHealth,
    AskTopic.commonEveryday,
    AskTopic.commonAnything,
  ]) {
    if (picked.length >= maxSuggestions) break;
    picked.add(SuggestedQuestion(topic));
  }

  return picked.take(maxSuggestions).toList();
}

AskTopic _byAge(int months) {
  if (months < 2) return AskTopic.newbornFeeding;
  if (months < 4) return AskTopic.sleepNeeds;
  if (months < 8) return AskTopic.solids;
  return AskTopic.milestones;
}

/// The highest reading of the current day, if the thermometer came out.
double? _highestToday(List<DevelopmentLog> logs, DateTime now) {
  final today = dateOnly(now);
  double? highest;
  for (final log in logs) {
    final t = log.metrics.temperatureC;
    if (t == null || log.date.isAfter(now)) continue;
    if (dateOnly(log.date) != today) continue;
    if (highest == null || t > highest) highest = t;
  }
  return highest;
}

/// Wakings from the most recent night block — last night's, or the one that
/// started yesterday evening and is what this morning is living with.
int? _lastNightWakings(List<DevelopmentLog> logs, DateTime now) {
  final earliest = dateOnly(now).subtract(const Duration(days: 1));
  DateTime? at;
  int? wakings;

  for (final log in logs) {
    if (!log.isNightSleep || log.date.isAfter(now)) continue;
    if (log.date.isBefore(earliest)) continue;
    if (at == null || log.date.isAfter(at)) {
      at = log.date;
      wakings = log.nightWakings;
    }
  }
  return wakings;
}

/// True when the diary is alive but no nappy has been written down for a day.
///
/// The "alive" half matters: on a diary nobody has touched for a week, every
/// gap is a day long, and offering a question about the last one would be the
/// app reading its own silence as a symptom.
bool _nappiesAreQuiet(List<DevelopmentLog> logs, DateTime now) {
  DateTime? lastNappy;
  DateTime? lastAnything;

  for (final log in logs) {
    if (log.date.isAfter(now)) continue;
    if (lastAnything == null || log.date.isAfter(lastAnything)) {
      lastAnything = log.date;
    }
    if (log.type != LogType.nappy) continue;
    if (lastNappy == null || log.date.isAfter(lastNappy)) lastNappy = log.date;
  }

  if (lastAnything == null) return false;
  if (now.difference(lastAnything).inHours >= _quietNappyHours) return false;
  if (lastNappy == null) return false;
  return now.difference(lastNappy).inHours >= _quietNappyHours;
}

extension SuggestedQuestionL10n on SuggestedQuestion {
  /// What gets sent when she taps it.
  String question(AppLocalizations l) => switch (topic) {
    AskTopic.temperatureToday => l.askTemperature(
      temperature!.toStringAsFixed(1),
    ),
    AskTopic.hardNight => l.askHardNight(wakings ?? 0),
    AskTopic.quietNappies => l.askQuietNappies,
    AskTopic.newbornFeeding => l.askNewbornFeeding,
    AskTopic.sleepNeeds => l.askSleepNeeds,
    AskTopic.solids => l.askSolids,
    AskTopic.milestones => l.askMilestones,
    AskTopic.commonHealth => l.chatSuggestion1,
    AskTopic.commonEveryday => l.chatSuggestion2,
    AskTopic.commonAnything => l.chatSuggestion3,
  };

  /// The line under it: where the app got this from. Null where there is no
  /// honest answer but "everybody asks it".
  String? reason(AppLocalizations l) => switch (topic) {
    AskTopic.temperatureToday => l.askWhyTemperature(
      temperature!.toStringAsFixed(1),
    ),
    AskTopic.hardNight => l.askWhyHardNight(wakings ?? 0),
    AskTopic.quietNappies => l.askWhyQuietNappies,
    AskTopic.newbornFeeding ||
    AskTopic.sleepNeeds ||
    AskTopic.solids ||
    AskTopic.milestones => l.askWhyAge,
    AskTopic.commonHealth ||
    AskTopic.commonEveryday ||
    AskTopic.commonAnything => null,
  };
}
