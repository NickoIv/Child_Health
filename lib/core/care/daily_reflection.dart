import '../../models/development_log.dart';
import '../../models/json.dart';

/// The day added up, in the evening, from entries she already made.
///
/// Counting, and nothing else. There is no reading of the numbers here, no
/// comparison against a norm or against yesterday, and no suggestion that any
/// of it means anything — those are conclusions, and this is arithmetic she
/// would otherwise do in her head at the end of a day when she has least left
/// to do it with.
class DailyReflection {
  const DailyReflection({
    required this.feedings,
    required this.sleepMinutes,
    required this.nappies,
    required this.events,
    this.temperatureC,
  });

  final int feedings;
  final int sleepMinutes;
  final int nappies;

  /// Everything recorded on the day, of any type — what the threshold counts.
  final int events;

  /// The highest reading of the day, if one was taken. Stated as a fact and
  /// never interpreted.
  final double? temperatureC;

  bool get hasTemperature => temperatureC != null;
}

/// Evening only. Before this the day is still happening, and summing up a day
/// at two in the afternoon is just a second dashboard.
const _fromHour = 18;

/// Below this there is nothing to add up, and a card that says "1 feeding"
/// costs more attention than it returns.
const _minEvents = 3;

/// The day's totals, or null if there is nothing to show yet.
///
/// [dismissedDay] is the day she waved it away on; a new day starts clean.
DailyReflection? reflectionFor(
  List<DevelopmentLog> logs,
  DateTime now, {
  DateTime? dismissedDay,
}) {
  final today = dateOnly(now);
  if (now.hour < _fromHour) return null;
  if (dismissedDay != null && dateOnly(dismissedDay) == today) return null;

  var events = 0;
  var feedings = 0;
  var nappies = 0;
  var sleep = 0;
  double? temperature;

  for (final log in logs) {
    if (dateOnly(log.date) != today || log.date.isAfter(now)) continue;
    events++;

    switch (log.type) {
      case LogType.feeding:
        feedings++;
      case LogType.nappy:
        nappies++;
      case LogType.sleep:
        sleep += log.durationMinutes ?? 0;
      default:
        break;
    }

    final t = log.metrics.temperatureC;
    if (t != null && (temperature == null || t > temperature)) temperature = t;
  }

  if (events < _minEvents) return null;

  return DailyReflection(
    feedings: feedings,
    sleepMinutes: sleep,
    nappies: nappies,
    events: events,
    temperatureC: temperature,
  );
}
