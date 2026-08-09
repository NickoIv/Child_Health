import '../../models/development_log.dart';
import '../../models/json.dart';

/// What happened today: feeds, nappies, sleep.
///
/// These exist because the knowledge base already tells a parent to count
/// them — "8-12 feeds a day", "six or more wet nappies" — and until now the
/// app gave her nowhere to do it. A rule you cannot check is advice you
/// cannot use.
class DailyCare {
  const DailyCare({
    required this.feedings,
    required this.wetNappies,
    required this.dirtyNappies,
    required this.sleepMinutes,
    this.lastFeedingAt,
    this.lastNappyAt,
    this.lastSleepAt,
    this.lastSleepMinutes,
  });

  final int feedings;
  final int wetNappies;
  final int dirtyNappies;
  final int sleepMinutes;
  final DateTime? lastFeedingAt;
  final DateTime? lastNappyAt;

  /// The most recent stretch of sleep and how long it ran. The second question
  /// every parent is asked, after when the baby last ate.
  final DateTime? lastSleepAt;
  final int? lastSleepMinutes;

  bool get isEmpty =>
      feedings == 0 &&
      wetNappies == 0 &&
      dirtyNappies == 0 &&
      sleepMinutes == 0;

  /// Minutes since the last feed, or null if none recorded.
  int? minutesSinceFeeding(DateTime now) => lastFeedingAt == null
      ? null
      : now.difference(lastFeedingAt!).inMinutes;
}

/// The last feed on record, whatever day it happened on.
///
/// Deliberately not [DailyCare.lastFeedingAt], which stops at midnight: the
/// question this answers — which breast was last — is asked most often at two
/// in the morning, when the previous feed was yesterday and the count for
/// today is one. Logs arrive newest first, so the first match is the answer.
DevelopmentLog? lastFeedingIn(List<DevelopmentLog> logs) {
  for (final log in logs) {
    if (log.type == LogType.feeding) return log;
  }
  return null;
}

/// How a count compares with what the knowledge base expects.
enum CareStatus { onTrack, watch, unknown }

/// Thresholds taken from the articles, not invented here.
///
/// `enough-milk`: six or more wet nappies a day after the first week, and
/// 8-12 feeds in twenty-four hours. Both are stated as the concrete check a
/// parent can run at home, which is exactly why they are worth counting.
abstract final class CareTargets {
  static const minWetNappies = 6;
  static const minFeedings = 8;

  /// Only meaningful once a full day has been recorded, so a morning with
  /// two feeds logged does not accuse anyone of anything.
  static CareStatus wetNappyStatus(int count, {required bool dayComplete}) {
    if (!dayComplete) return CareStatus.unknown;
    return count >= minWetNappies ? CareStatus.onTrack : CareStatus.watch;
  }

  static CareStatus feedingStatus(int count, {required bool dayComplete}) {
    if (!dayComplete) return CareStatus.unknown;
    return count >= minFeedings ? CareStatus.onTrack : CareStatus.watch;
  }
}

/// Aggregates [logs] for the calendar day containing [day].
DailyCare dailyCareFor(List<DevelopmentLog> logs, DateTime day) {
  final target = dateOnly(day);

  var feedings = 0;
  var wet = 0;
  var dirty = 0;
  var sleep = 0;
  DateTime? lastFeeding;
  DateTime? lastNappy;
  DateTime? lastSleep;
  int? lastSleepMinutes;

  for (final log in logs) {
    if (dateOnly(log.date) != target) continue;

    switch (log.type) {
      case LogType.feeding:
        feedings++;
        if (lastFeeding == null || log.date.isAfter(lastFeeding)) {
          lastFeeding = log.date;
        }
      case LogType.nappy:
        final kind = log.nappyKind;
        if (kind == null) break;
        if (kind.countsAsWet) wet++;
        if (kind.countsAsDirty) dirty++;
        if (lastNappy == null || log.date.isAfter(lastNappy)) {
          lastNappy = log.date;
        }
      case LogType.sleep:
        sleep += log.durationMinutes ?? 0;
        if (lastSleep == null || log.date.isAfter(lastSleep)) {
          lastSleep = log.date;
          lastSleepMinutes = log.durationMinutes;
        }
      default:
        break;
    }
  }

  return DailyCare(
    feedings: feedings,
    wetNappies: wet,
    dirtyNappies: dirty,
    sleepMinutes: sleep,
    lastFeedingAt: lastFeeding,
    lastNappyAt: lastNappy,
    lastSleepAt: lastSleep,
    lastSleepMinutes: lastSleepMinutes,
  );
}
