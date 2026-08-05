import '../../models/development_log.dart';
import '../../models/json.dart';

/// What makes a day a hard one.
///
/// Three plain counts, held here rather than inline so the numbers can be
/// argued about without touching the wording — and so it is obvious that this
/// is arithmetic over what she wrote down, not an assessment of anybody.
abstract final class HeavyDayThresholds {
  /// Entries in a day. Ten is a day spent writing things down.
  static const events = 10;

  /// Wake-ups in one night. The same four the digest calls a hard night.
  static const nightWakings = 4;

  /// A fever, in Celsius.
  static const temperature = 38.0;
}

/// Whether the day around [day] was a hard one.
///
/// Deliberately not a score, a trend or a comparison with any other day. It
/// answers one yes-or-no question, and the only thing that hangs on the answer
/// is whether a single sentence appears.
bool wasHeavyDay(List<DevelopmentLog> logs, DateTime day) {
  final target = dateOnly(day);
  final yesterday = target.subtract(const Duration(days: 1));

  var events = 0;
  var wakings = 0;
  var fever = false;

  for (final log in logs) {
    final on = dateOnly(log.date);

    // Last night was entered as one block dated to the evening it began, so
    // the night this morning is living with sits on yesterday's date.
    if (log.isNightSleep && (on == target || on == yesterday)) {
      final count = log.nightWakings ?? 0;
      if (count > wakings) wakings = count;
    }

    if (on != target) continue;
    events++;

    final temperature = log.metrics.temperatureC;
    if (temperature != null && temperature >= HeavyDayThresholds.temperature) {
      fever = true;
    }
  }

  return events >= HeavyDayThresholds.events ||
      wakings >= HeavyDayThresholds.nightWakings ||
      fever;
}
