import '../../models/development_log.dart';
import '../../models/json.dart';

/// Habits, read back from what has already been written down.
///
/// Every one of these is a description of this child's own recent days, and it
/// stops at the description. There is no norm anywhere here, nothing is called
/// enough or too little, and none of it is advice — the most the app will say
/// is that a thing has been happening at roughly the same time lately.
enum PatternKind {
  sleepThenFeeding('sleep_then_feeding'),
  nightStart('night_start'),
  stableSleep('stable_sleep');

  const PatternKind(this.code);

  final String code;
}

class PatternObservation {
  const PatternObservation({required this.kind, this.nightStartMinutes});

  final PatternKind kind;

  /// Minutes past midnight the night usually begins, for [PatternKind
  /// .nightStart]. Kept as a number so the wording and the clock format stay
  /// in the widget layer.
  final int? nightStartMinutes;
}

/// Nothing is offered until there is a week's worth of days to look back over,
/// and never on fewer than three of them.
const _windowDays = 7;
const _minDays = 3;

/// A feed that follows a nap this closely is the pair the first observation is
/// about. Wider than the sentence it produces on purpose: the claim is about
/// where the gap usually lands, not where it always does.
const _afterSleepMinGap = 15;
const _afterSleepMaxGap = 60;

/// How far apart bedtimes may drift and still be called usual.
const _nightSpreadMinutes = 45;

/// And how far daily sleep totals may drift before "about the same" stops
/// being true.
const _stableSleepMinutes = 60;

/// The one observation worth making today, or null.
///
/// Computed over completed days only, which is what makes it change once a
/// day rather than shifting under the parent as she records things.
PatternObservation? patternFor(
  List<DevelopmentLog> logs,
  DateTime now, {
  DateTime? dismissedDay,
}) {
  final today = dateOnly(now);
  if (dismissedDay != null && dateOnly(dismissedDay) == today) return null;

  final days = <DateTime>[];
  for (var back = 1; back <= _windowDays; back++) {
    days.add(dateOnly(today.subtract(Duration(days: back))));
  }

  final recorded = days
      .where((day) => logs.any((log) => dateOnly(log.date) == day))
      .toList();
  if (recorded.length < _minDays) return null;

  if (_napThenFeeding(logs, recorded)) {
    return const PatternObservation(kind: PatternKind.sleepThenFeeding);
  }

  final bedtime = _usualNightStart(logs, days);
  if (bedtime != null) {
    return PatternObservation(
      kind: PatternKind.nightStart,
      nightStartMinutes: bedtime,
    );
  }

  if (_steadySleep(logs, recorded)) {
    return const PatternObservation(kind: PatternKind.stableSleep);
  }

  return null;
}

/// Days on which a nap was followed by a feed within the window.
bool _napThenFeeding(List<DevelopmentLog> logs, List<DateTime> days) {
  var matching = 0;

  for (final day in days) {
    final naps = <DateTime>[];
    final feeds = <DateTime>[];

    for (final log in logs) {
      if (dateOnly(log.date) != day) continue;
      if (log.type == LogType.sleep && !log.isNightSleep) {
        naps.add(log.date.add(Duration(minutes: log.durationMinutes ?? 0)));
      } else if (log.type == LogType.feeding) {
        feeds.add(log.date);
      }
    }
    if (naps.isEmpty || feeds.isEmpty) continue;

    final paired = naps.any((wokeAt) {
      // The first feed after the nap, not any feed: a bottle three hours
      // later says nothing about waking up.
      DateTime? next;
      for (final feed in feeds) {
        if (!feed.isAfter(wokeAt)) continue;
        if (next == null || feed.isBefore(next)) next = feed;
      }
      if (next == null) return false;

      final gap = next.difference(wokeAt).inMinutes;
      return gap >= _afterSleepMinGap && gap <= _afterSleepMaxGap;
    });

    if (paired) matching++;
  }

  return matching >= _minDays;
}

/// The hour the night usually starts, when the nights agree closely enough.
int? _usualNightStart(List<DevelopmentLog> logs, List<DateTime> days) {
  final starts = <int>[];
  for (final log in logs) {
    if (!log.isNightSleep) continue;
    if (!days.contains(dateOnly(log.date))) continue;

    final minutes = log.date.hour * 60 + log.date.minute;
    // A night begun after midnight is later than one begun at ten, not
    // twenty-two hours earlier. Without this the mean lands at lunchtime.
    starts.add(minutes < 12 * 60 ? minutes + 24 * 60 : minutes);
  }
  if (starts.length < _minDays) return null;

  final mean = starts.reduce((a, b) => a + b) / starts.length;
  final spread = starts
      .map((m) => (m - mean).abs())
      .reduce((a, b) => a > b ? a : b);
  if (spread > _nightSpreadMinutes) return null;

  return mean.round() % (24 * 60);
}

/// Daily sleep totals that have been landing close together.
bool _steadySleep(List<DevelopmentLog> logs, List<DateTime> days) {
  final totals = <int>[];
  for (final day in days) {
    var minutes = 0;
    for (final log in logs) {
      if (log.type != LogType.sleep || dateOnly(log.date) != day) continue;
      minutes += log.durationMinutes ?? 0;
    }
    // A day with no sleep recorded is a gap in the diary, not a day without
    // sleep, and averaging it in would invent a swing.
    if (minutes > 0) totals.add(minutes);
  }
  if (totals.length < _minDays) return false;

  final lowest = totals.reduce((a, b) => a < b ? a : b);
  final highest = totals.reduce((a, b) => a > b ? a : b);
  return highest - lowest < _stableSleepMinutes;
}
