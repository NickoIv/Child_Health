import '../../models/development_log.dart';

/// When this child is likely to be ready to sleep again.
///
/// The one thing in this app that says something about the next hour rather
/// than about the last one, and the reason it is allowed to: it is arithmetic
/// on two things a parent can check. The first is her own fortnight of entries
/// — how long he has actually been awake between sleeps. The second is the
/// published wake window for his age, used only until there are enough of her
/// own observations to beat it.
///
/// It never says what to do. A prediction that ends in an instruction is a
/// stranger telling a mother when to put her child down; a prediction that
/// ends in a time is the answer to «успею ли я в душ», which is the question
/// actually being asked.

/// How long a child of this age is usually awake between sleeps.
///
/// The ordinary paediatric wake windows, in the form every sleep book prints
/// them: they widen fast in the first half-year and then slowly. Deliberately
/// the middle of each published range rather than its top — this figure is the
/// centre of a guess, and the card says so.
int ageWakeWindowMinutes(int months) => switch (months) {
  < 1 => 50,
  < 2 => 65,
  < 3 => 80,
  < 4 => 95,
  < 6 => 120,
  < 9 => 150,
  < 12 => 180,
  < 18 => 225,
  < 24 => 285,
  _ => 330,
};

/// Past three the windows stop describing anything: a child that age either
/// naps once at a fixed hour or does not nap at all, and neither is a gap to
/// be measured from the last sleep.
const forecastMaxAgeMonths = 36;

/// How many of her own gaps it takes before they beat the age table.
///
/// Four is low on purpose. Three gaps of an hour and a half from a child the
/// book says should manage two hours are still worth more than the book — it
/// is *his* fortnight, and she is the one who watched it.
const minForecastSamples = 4;

/// How far back the personal figure is measured over.
const forecastHistoryDays = 14;

/// The shortest and longest gap that counts as "awake between sleeps".
///
/// Under twenty minutes is a stir written down as two naps; over eight hours
/// is a day with a nap missing from it, and averaging that in would teach the
/// app that this child stays up for a working day.
const _minGapMinutes = 20;
const _maxGapMinutes = 8 * 60;

class SleepForecast {
  const SleepForecast({
    required this.expectedAt,
    required this.awakeSince,
    required this.windowMinutes,
    required this.samples,
  });

  /// When the wake window runs out.
  final DateTime expectedAt;

  /// When the last recorded sleep ended.
  final DateTime awakeSince;

  /// The window the estimate used, in minutes.
  final int windowMinutes;

  /// How many of this child's own gaps stand behind it. Zero means the figure
  /// is the age table's and the card must say so.
  final int samples;

  /// Whether the number is his rather than the book's.
  bool get personal => samples >= minForecastSamples;

  int awakeMinutesAt(DateTime now) => now.difference(awakeSince).inMinutes;

  /// Negative once the window has passed.
  int minutesLeftAt(DateTime now) => expectedAt.difference(now).inMinutes;

  bool isOverdueAt(DateTime now) => now.isAfter(expectedAt);
}

/// How near the end of the window the card is worth showing.
///
/// Three quarters of an hour ahead is enough to finish what she is doing;
/// earlier than that it is a countdown nobody asked for. It stays for an hour
/// past the estimate, because a window that has just closed is exactly when a
/// parent wonders whether the crying is tiredness.
const forecastLeadMinutes = 45;
const forecastLingerMinutes = 60;

/// The forecast worth showing right now, or null.
///
/// Null is the common answer, and every one of these is a case where a number
/// would be a lie: a child too old for wake windows, a child asleep, a day
/// with no sleep written down at all, and a gap so long that the last entry
/// says nothing about this afternoon.
SleepForecast? sleepForecastFor(
  List<DevelopmentLog> logs,
  DateTime now, {
  required int ageMonths,
  bool asleep = false,
}) {
  if (asleep || ageMonths > forecastMaxAgeMonths) return null;

  final awakeSince = lastWakingAt(logs, now);
  if (awakeSince == null) return null;

  final window = wakeWindowFor(logs, now, ageMonths: ageMonths);
  final expectedAt = awakeSince.add(Duration(minutes: window.minutes));

  final left = expectedAt.difference(now).inMinutes;
  if (left > forecastLeadMinutes) return null;
  // Long past it, and the last sleep is stale rather than late: she has not
  // written a nap down since this morning, and an hours-overdue banner would
  // be the app complaining about her record-keeping.
  if (left < -forecastLingerMinutes) return null;

  return SleepForecast(
    expectedAt: expectedAt,
    awakeSince: awakeSince,
    windowMinutes: window.minutes,
    samples: window.samples,
  );
}

/// The end of the most recent sleep that has actually finished.
DateTime? lastWakingAt(List<DevelopmentLog> logs, DateTime now) {
  DateTime? latest;
  for (final log in logs) {
    if (log.type != LogType.sleep) continue;
    final minutes = log.durationMinutes;
    // A sleep with no length is a note that he slept, not a stretch that
    // ended at a knowable time.
    if (minutes == null || minutes <= 0) continue;

    final end = log.date.add(Duration(minutes: minutes));
    if (end.isAfter(now)) continue;
    if (latest == null || end.isAfter(latest)) latest = end;
  }
  return latest;
}

/// The wake window to use for this child, and how many of his own gaps stand
/// behind it. Whatever time it is — the card asks whether it is worth showing;
/// this only answers how long he is usually up for.
({int minutes, int samples}) wakeWindowFor(
  List<DevelopmentLog> logs,
  DateTime now, {
  required int ageMonths,
}) {
  final gaps = observedWakeGaps(logs, now);
  if (gaps.length < minForecastSamples) {
    return (minutes: ageWakeWindowMinutes(ageMonths), samples: gaps.length);
  }
  return (minutes: _median(gaps), samples: gaps.length);
}

/// Every gap between one sleep ending and the next beginning, in the last
/// fortnight.
///
/// The median of these is what the card quotes. A median rather than a mean
/// because one four-hour car journey should not move the estimate for the
/// week, and a family has at least one of those a fortnight.
List<int> observedWakeGaps(List<DevelopmentLog> logs, DateTime now) {
  final from = now.subtract(const Duration(days: forecastHistoryDays));
  final sleeps =
      logs
          .where(
            (l) =>
                l.type == LogType.sleep &&
                (l.durationMinutes ?? 0) > 0 &&
                l.date.isAfter(from) &&
                !l.date.isAfter(now),
          )
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  final gaps = <int>[];
  for (var i = 1; i < sleeps.length; i++) {
    final previous = sleeps[i - 1];
    final end = previous.date.add(
      Duration(minutes: previous.durationMinutes!),
    );
    final gap = sleeps[i].date.difference(end).inMinutes;
    if (gap >= _minGapMinutes && gap <= _maxGapMinutes) gaps.add(gap);
  }
  return gaps;
}

int _median(List<int> values) {
  final sorted = [...values]..sort();
  final middle = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[middle]
      : ((sorted[middle - 1] + sorted[middle]) / 2).round();
}
