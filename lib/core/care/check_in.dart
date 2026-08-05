import '../../models/development_log.dart';
import '../../models/json.dart';

/// How she is, in her own words, on the morning after a hard night.
///
/// Three answers and one sentence back. Nothing here assesses her, nothing is
/// stored beyond the day, and nothing is inferred from what she taps — the
/// question is asked because the night was short, not because the app has a
/// theory about her.
enum CheckInAnswer {
  holdingUp('holding_up'),
  tired('tired'),
  veryHard('very_hard');

  const CheckInAnswer(this.code);

  final String code;

  static CheckInAnswer? fromCode(String? code) {
    for (final answer in CheckInAnswer.values) {
      if (answer.code == code) return answer;
    }
    return null;
  }
}

/// Morning only. In the evening the night is over and the question has
/// stopped being about today; at three in the morning it would be an
/// intrusion.
const _fromHour = 6;
const _untilHour = 12;

/// What counts as a night worth asking about.
const _shortNightMinutes = 5 * 60;
const _manyWakings = 4;

/// A night older than this belongs to a different morning.
const _nightWithinHours = 24;

bool isMorning(DateTime now) => now.hour >= _fromHour && now.hour < _untilHour;

/// Whether to ask this morning.
///
/// [shownDay] is the day it was last put to her, answered or waved away; one
/// a day is the whole of the restraint here.
bool checkInDue(
  List<DevelopmentLog> logs,
  DateTime now, {
  DateTime? shownDay,
}) {
  if (!isMorning(now)) return false;
  if (shownDay != null && dateOnly(shownDay) == dateOnly(now)) return false;

  DevelopmentLog? night;
  for (final log in logs) {
    if (!log.isNightSleep || log.date.isAfter(now)) continue;
    if (now.difference(log.date).inHours > _nightWithinHours) continue;
    if (night == null || log.date.isAfter(night.date)) night = log;
  }
  if (night == null) return false;

  final slept = night.durationMinutes ?? 0;
  final wakings = night.nightWakings ?? 0;
  return slept < _shortNightMinutes || wakings >= _manyWakings;
}
