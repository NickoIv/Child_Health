import '../../models/development_log.dart';

/// A nudge toward the entry a parent was probably about to make anyway.
///
/// Nothing here predicts anything about the child. Both rules are arithmetic
/// on entries she has already made — a nap ended and nothing was logged after
/// it, or the last nappy was hours ago — and the only thing offered is the
/// button she would have tapped herself. No advice, no conclusion, no claim
/// that anything is wrong.
enum SuggestionKind {
  afterSleep('after_sleep'),
  nappy('nappy');

  const SuggestionKind(this.code);

  final String code;

  static SuggestionKind? fromCode(String? code) {
    for (final kind in SuggestionKind.values) {
      if (kind.code == code) return kind;
    }
    return null;
  }
}

/// A nap has to have finished, and finished recently, before there is anything
/// to suggest: during the nap the answer is obvious, and three hours later the
/// moment has passed.
const _afterSleepMinMinutes = 10;
const _afterSleepMaxMinutes = 180;

/// How long a nappy goes unrecorded before it is worth mentioning. Comfortably
/// past a normal gap, so this is a reminder to write it down rather than a
/// claim that something was missed.
const _nappyQuietHours = 4;

/// Quiet hours. A parent awake at three with a screaming baby does not need
/// the app to have opinions.
const _quietFromHour = 22;
const _quietUntilHour = 6;

bool isQuietHour(DateTime now) =>
    now.hour >= _quietFromHour || now.hour < _quietUntilHour;

/// The single suggestion worth making right now, or null.
///
/// [dismissedUntil] is what the parent has already waved away, and one at a
/// time is the whole point: a dashboard that offers two things to do has
/// stopped suggesting and started nagging.
SuggestionKind? suggestionFor(
  List<DevelopmentLog> logs,
  DateTime now, {
  Map<SuggestionKind, DateTime> dismissedUntil = const {},
}) {
  if (isQuietHour(now)) return null;

  for (final kind in SuggestionKind.values) {
    final until = dismissedUntil[kind];
    if (until != null && now.isBefore(until)) continue;

    final applies = switch (kind) {
      SuggestionKind.afterSleep => _afterSleep(logs, now),
      SuggestionKind.nappy => _nappyQuiet(logs, now),
    };
    if (applies) return kind;
  }
  return null;
}

/// A nap that ended a little while ago with nothing recorded since.
bool _afterSleep(List<DevelopmentLog> logs, DateTime now) {
  DateTime? wokeAt;
  DateTime? lastFeeding;

  for (final log in logs) {
    if (log.date.isAfter(now)) continue;
    switch (log.type) {
      case LogType.sleep:
        final end = log.date.add(Duration(minutes: log.durationMinutes ?? 0));
        if (end.isAfter(now)) break;
        if (wokeAt == null || end.isAfter(wokeAt)) wokeAt = end;
      case LogType.feeding:
        if (lastFeeding == null || log.date.isAfter(lastFeeding)) {
          lastFeeding = log.date;
        }
      default:
        break;
    }
  }

  if (wokeAt == null) return false;

  final since = now.difference(wokeAt).inMinutes;
  if (since < _afterSleepMinMinutes || since > _afterSleepMaxMinutes) {
    return false;
  }

  // She has already fed since waking; there is nothing to suggest.
  return lastFeeding == null || lastFeeding.isBefore(wokeAt);
}

/// Nappies were being recorded, and then were not.
bool _nappyQuiet(List<DevelopmentLog> logs, DateTime now) {
  DateTime? last;
  for (final log in logs) {
    if (log.type != LogType.nappy || log.date.isAfter(now)) continue;
    if (last == null || log.date.isAfter(last)) last = log.date;
  }

  // Never a single one recorded is not a gap — it is a parent who does not
  // use this part of the app, and pestering her about it would be rude.
  if (last == null) return false;

  return now.difference(last).inHours >= _nappyQuietHours;
}
