import '../../models/development_log.dart';
import '../../models/json.dart';
import 'daily_care.dart';

/// How the day reads, in one sentence.
///
/// Three, and only three. A scale with seven steps would invite the reader to
/// work out which step today is and why it is not the one above — and this
/// line is written for a father checking his phone between meetings, not for
/// a chart.
///
/// It describes the day, never the child and never the mother. "Busy" is a
/// fact about how much was written down; it is not a verdict on anybody.
enum DayMood { calm, busy, hardNight }

/// Today, for someone who was not there.
///
/// Deliberately the five things that answer "is everything all right" and
/// nothing that answers "what should be done about it". A viewer cannot act
/// on this record, so a digest that raised questions would only be a way of
/// asking the mother to explain herself.
class DailyDigest {
  const DailyDigest({
    required this.feedings,
    required this.sleepMinutes,
    required this.nappies,
    required this.photos,
    required this.mood,
    this.lastTemperature,
    this.nightWakings,
  });

  final int feedings;
  final int sleepMinutes;
  final int nappies;
  final int photos;

  /// The most recent reading of the day, if anyone took one. Absent is the
  /// normal case and shows as nothing at all rather than as a dash.
  final double? lastTemperature;

  /// Wake-ups from last night's sleep, where a night was recorded. Not shown
  /// as a number — it only decides whether the line mentions the night.
  final int? nightWakings;

  final DayMood mood;

  /// Nothing recorded yet. The card says so instead of showing five zeroes,
  /// which reads as an alarm rather than as an ordinary quiet morning.
  bool get isEmpty =>
      feedings == 0 &&
      sleepMinutes == 0 &&
      nappies == 0 &&
      photos == 0 &&
      lastTemperature == null;
}

/// What counts as a lot, and what counts as a hard night.
///
/// Both thresholds are held here rather than inline so the wording and the
/// arithmetic can be argued about separately.
abstract final class DigestThresholds {
  /// Above this many entries in a day, the day was busy. Sits above the
  /// knowledge base's 8-12 feeds plus six nappies, so an ordinary well-logged
  /// day is still a calm one.
  static const busyEntries = 22;

  /// Wake-ups that make a night worth mentioning. Two is a normal newborn
  /// night; four is the night nobody slept.
  static const hardNightWakings = 4;
}

/// Builds the digest from what is already recorded. No new collection, no new
/// document, no second source of truth — the same logs and the same photo ids
/// the diary is built from.
DailyDigest buildDailyDigest(List<DevelopmentLog> logs, DateTime day) {
  final target = dateOnly(day);
  final care = dailyCareFor(logs, day);

  var photos = 0;
  double? lastTemperature;
  DateTime? lastTemperatureAt;
  int? nightWakings;
  var entries = 0;

  for (final log in logs) {
    if (dateOnly(log.date) != target) continue;
    entries++;
    photos += log.photos.length;

    final temperature = log.metrics.temperatureC;
    if (temperature != null &&
        (lastTemperatureAt == null || log.date.isAfter(lastTemperatureAt))) {
      lastTemperature = temperature;
      lastTemperatureAt = log.date;
    }

    // The night belonging to this morning was entered as one block, dated to
    // the evening it started — so both today's night and yesterday's count,
    // and the later of the two wins.
    if (log.isNightSleep) {
      nightWakings = log.nightWakings;
    }
  }

  // Yesterday evening's night is the one this morning is living with.
  if (nightWakings == null) {
    final yesterday = target.subtract(const Duration(days: 1));
    for (final log in logs) {
      if (!log.isNightSleep) continue;
      if (dateOnly(log.date) != yesterday) continue;
      nightWakings = log.nightWakings;
      break;
    }
  }

  return DailyDigest(
    feedings: care.feedings,
    sleepMinutes: care.sleepMinutes,
    nappies: care.wetNappies + care.dirtyNappies,
    photos: photos,
    lastTemperature: lastTemperature,
    nightWakings: nightWakings,
    mood: moodFor(entries: entries, nightWakings: nightWakings),
  );
}

/// Picks the sentence.
///
/// The night wins over the day: if nobody slept, saying the day was calm is
/// the kind of cheerfulness that makes an app feel like it is not paying
/// attention.
DayMood moodFor({required int entries, int? nightWakings}) {
  if ((nightWakings ?? 0) >= DigestThresholds.hardNightWakings) {
    return DayMood.hardNight;
  }
  return entries > DigestThresholds.busyEntries ? DayMood.busy : DayMood.calm;
}
