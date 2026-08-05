import '../../models/child.dart';
import '../../models/development_log.dart';
import '../../models/json.dart';

/// How far back the report looks.
enum ReportPeriod {
  week(7),
  twoWeeks(14),
  month(30);

  const ReportPeriod(this.days);

  final int days;
}

/// One dated line in the report — a dose given, or something written down.
typedef ReportEntry = ({DateTime at, String text});

/// The period, counted.
///
/// Counting and nothing else: no averages against a norm, no comparison with
/// last month, no note about what any of it might mean. A doctor reads the
/// numbers; the app's job is to have them ready and to be right about them.
class PeriodReport {
  const PeriodReport({
    required this.child,
    required this.period,
    required this.from,
    required this.to,
    required this.nights,
    required this.averageNightMinutes,
    required this.averageWakings,
    required this.daysWithNaps,
    required this.averageDayNapMinutes,
    required this.feedings,
    required this.breastFeedings,
    required this.bottleFeedings,
    required this.wetNappies,
    required this.dirtyNappies,
    required this.bothNappies,
    required this.temperatureCount,
    required this.medicines,
    required this.notes,
    this.maxTemperature,
    this.minTemperature,
  });

  final Child child;
  final ReportPeriod period;
  final DateTime from;
  final DateTime to;

  final int nights;
  final int averageNightMinutes;
  final double averageWakings;
  final int daysWithNaps;
  final int averageDayNapMinutes;

  final int feedings;
  final int breastFeedings;
  final int bottleFeedings;

  final int wetNappies;
  final int dirtyNappies;
  final int bothNappies;

  final double? maxTemperature;
  final double? minTemperature;
  final int temperatureCount;

  final List<ReportEntry> medicines;
  final List<ReportEntry> notes;

  /// Each section is printed only if the period actually holds it. A heading
  /// over three dashes tells a doctor nothing and costs him a glance.
  bool get hasSleep => nights > 0 || daysWithNaps > 0;
  bool get hasFeeding => feedings > 0;
  bool get hasNappies => wetNappies + dirtyNappies + bothNappies > 0;
  bool get hasTemperature => temperatureCount > 0;
  bool get hasMedicines => medicines.isNotEmpty;
  bool get hasNotes => notes.isNotEmpty;

  bool get isEmpty =>
      !hasSleep && !hasFeeding && !hasNappies && !hasTemperature &&
      !hasMedicines && !hasNotes;
}

/// The last five notes are enough to jog a memory; a full diary is a different
/// document and not one a doctor reads in a five-minute appointment.
const _noteLimit = 5;

PeriodReport buildPeriodReport(
  Child child,
  List<DevelopmentLog> logs,
  ReportPeriod period, {
  DateTime? now,
}) {
  final to = now ?? DateTime.now();
  final from = dateOnly(to).subtract(Duration(days: period.days - 1));

  var nightCount = 0;
  var nightMinutes = 0;
  var wakings = 0;
  var feedings = 0;
  var breast = 0;
  var bottle = 0;
  var wet = 0;
  var dirty = 0;
  var both = 0;
  var temperatures = 0;
  double? maxTemp;
  double? minTemp;

  // Naps are averaged per day rather than per nap: "about two hours" is the
  // answer to the question a doctor asks, and the number of naps it took to
  // get there is not.
  final napMinutesByDay = <DateTime, int>{};
  final medicines = <ReportEntry>[];
  final notes = <ReportEntry>[];

  for (final log in logs) {
    final day = dateOnly(log.date);
    if (day.isBefore(from) || log.date.isAfter(to)) continue;

    switch (log.type) {
      case LogType.sleep:
        if (log.isNightSleep) {
          nightCount++;
          nightMinutes += log.durationMinutes ?? 0;
          wakings += log.nightWakings ?? 0;
        } else {
          napMinutesByDay.update(
            day,
            (m) => m + (log.durationMinutes ?? 0),
            ifAbsent: () => log.durationMinutes ?? 0,
          );
        }
      case LogType.feeding:
        feedings++;
        if (log.feedingSide == FeedingSide.bottle) {
          bottle++;
        } else if (log.feedingSide != null) {
          breast++;
        }
      case LogType.nappy:
        switch (log.nappyKind) {
          case NappyKind.wet:
            wet++;
          case NappyKind.dirty:
            dirty++;
          case NappyKind.both:
            both++;
          case null:
            break;
        }
      case LogType.note:
        final text = log.description.trim();
        if (log.title == LogTitles.medicine) {
          medicines.add((at: log.date, text: text));
        } else {
          notes.add((at: log.date, text: text.isEmpty ? log.title : text));
        }
      default:
        break;
    }

    final t = log.metrics.temperatureC;
    if (t != null) {
      temperatures++;
      if (maxTemp == null || t > maxTemp) maxTemp = t;
      if (minTemp == null || t < minTemp) minTemp = t;
    }
  }

  medicines.sort((a, b) => a.at.compareTo(b.at));
  notes.sort((a, b) => b.at.compareTo(a.at));

  final napDays = napMinutesByDay.length;
  final napTotal = napMinutesByDay.values.fold(0, (a, b) => a + b);

  return PeriodReport(
    child: child,
    period: period,
    from: from,
    to: to,
    nights: nightCount,
    averageNightMinutes: nightCount == 0 ? 0 : nightMinutes ~/ nightCount,
    averageWakings: nightCount == 0 ? 0 : wakings / nightCount,
    daysWithNaps: napDays,
    averageDayNapMinutes: napDays == 0 ? 0 : napTotal ~/ napDays,
    feedings: feedings,
    breastFeedings: breast,
    bottleFeedings: bottle,
    wetNappies: wet,
    dirtyNappies: dirty,
    bothNappies: both,
    maxTemperature: maxTemp,
    minTemperature: minTemp,
    temperatureCount: temperatures,
    medicines: List.unmodifiable(medicines),
    notes: List.unmodifiable(notes.take(_noteLimit)),
  );
}
