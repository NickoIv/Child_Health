import '../../models/child.dart';
import '../../models/development_log.dart';
import '../../models/json.dart';
import '../../models/medical_record.dart';
import '../../models/reminder.dart';
import 'solids.dart';

/// What to have in hand at the appointment.
///
/// Every visit ends the same way — «есть ещё вопросы?» — and the four things
/// that mattered at three in the morning are gone. This assembles the answer
/// out of what is already written down: the questions she typed, the last time
/// he was weighed, the doses the calendar says are due, the foods still being
/// watched, and what happened since the last visit.
///
/// Nothing here is a new thing to fill in, and nothing here is advice. Every
/// line is a fact with a date on it, so that a doctor is told what happened
/// and never what an app thinks of it.

/// How far back the summary looks when there is no previous visit to count
/// from.
const visitWindowDays = 30;

/// And the furthest back it will ever look.
///
/// A visit eight months ago is not the period anyone is asking about. Without
/// the cap, a year of medicines arrives at a five-minute appointment.
const visitMaxWindowDays = 90;

/// How far ahead a dose counts as due at this visit.
///
/// Two weeks: near enough that it is worth asking about while sitting in front
/// of the doctor, far enough that the question is not «а когда?» a fortnight
/// later.
const visitVaccineHorizonDays = 14;

/// How long a weight and a height stay current.
///
/// Monthly in the first year, because that is how often a healthy baby is
/// weighed and how often the growth curve needs a point to stay a curve. The
/// extra five days are slack: a mother who weighs him on the same day every
/// month should not be told she is late every single month.
int measurementFreshDays(int ageMonths) => ageMonths < 12 ? 35 : 100;

/// How ready one line of the preparation is.
///
/// [missing] is not a reproach — it is «этого ещё нет», and for questions it
/// is the normal state of a week when nothing worried anybody.
enum PrepState { ready, attention, missing }

/// The appointment, as far as the app can prepare for it.
class VisitPrep {
  const VisitPrep({
    required this.now,
    required this.since,
    required this.ageMonths,
    required this.questions,
    required this.vaccines,
    required this.newFoods,
    required this.watchedFoods,
    required this.reactedFoods,
    required this.medicines,
    required this.sickDays,
    this.lastVisit,
    this.lastMeasurement,
    this.maxTemperature,
  });

  final DateTime now;

  /// Start of the period the summary covers — the last visit, or a month back
  /// when there has never been one. Shown on screen, because a count without
  /// the window it was taken over is a number nobody can use.
  final DateTime since;

  /// The newest medical record, which is the closest thing to a date of the
  /// last appointment the app has.
  final DateTime? lastVisit;

  final int ageMonths;

  /// Still unanswered, oldest first: the one that has waited longest is the
  /// one most likely to be forgotten again.
  final List<DevelopmentLog> questions;

  /// The last entry that carries a weight or a height.
  final DevelopmentLog? lastMeasurement;

  /// Doses already overdue or falling due within [visitVaccineHorizonDays],
  /// earliest first.
  final List<Reminder> vaccines;

  /// Foods first given since [since] — what a doctor means by «что нового».
  final List<FoodRecord> newFoods;

  /// Foods still inside their three-day watch.
  final List<FoodRecord> watchedFoods;

  /// Every food that ever caused a reaction, newest introduction first. Not
  /// limited to the period: «на что была реакция» is a question about his
  /// whole life, and a rash in March still belongs in the answer in August.
  final List<FoodRecord> reactedFoods;

  /// Doses given since [since], newest first.
  final List<DevelopmentLog> medicines;

  /// Distinct days marked as illness in the period.
  final int sickDays;

  /// Highest temperature recorded in the period.
  final double? maxTemperature;

  int get daysCovered => dateOnly(now).difference(dateOnly(since)).inDays;

  int? get measurementAgeDays => lastMeasurement == null
      ? null
      : dateOnly(now).difference(dateOnly(lastMeasurement!.date)).inDays;

  bool get measurementIsStale =>
      (measurementAgeDays ?? 0) > measurementFreshDays(ageMonths);

  /// The next dose to come up, due or overdue.
  Reminder? get nextVaccine => vaccines.isEmpty ? null : vaccines.first;

  bool get hasOverdueVaccine =>
      vaccines.any((v) => v.scheduledTime.isBefore(now));

  bool get hasSolids =>
      newFoods.isNotEmpty || watchedFoods.isNotEmpty || reactedFoods.isNotEmpty;

  PrepState get questionsState =>
      questions.isEmpty ? PrepState.missing : PrepState.ready;

  PrepState get measurementState => switch (lastMeasurement) {
    null => PrepState.missing,
    _ when measurementIsStale => PrepState.attention,
    _ => PrepState.ready,
  };

  PrepState get vaccineState =>
      hasOverdueVaccine ? PrepState.attention : PrepState.ready;

  /// Attention when there is something to say out loud: a food still being
  /// watched, or one that caused something.
  PrepState get solidsState {
    if (watchedFoods.isNotEmpty || reactedFoods.isNotEmpty) {
      return PrepState.attention;
    }
    return hasSolids ? PrepState.ready : PrepState.missing;
  }

  /// Whether the period holds anything worth a line of its own.
  bool get hasHistory =>
      sickDays > 0 || maxTemperature != null || medicines.isNotEmpty;
}

VisitPrep buildVisitPrep({
  required Child child,
  required List<DevelopmentLog> logs,
  required List<Reminder> reminders,
  required List<MedicalRecord> records,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();

  // The newest appointment already on file. A record dated in the future is a
  // typo, not an appointment that has happened.
  DateTime? lastVisit;
  for (final record in records) {
    if (record.date.isAfter(today)) continue;
    if (lastVisit == null || record.date.isAfter(lastVisit)) {
      lastVisit = record.date;
    }
  }

  final floor = dateOnly(today).subtract(
    const Duration(days: visitMaxWindowDays),
  );
  final fallback = dateOnly(today).subtract(
    const Duration(days: visitWindowDays),
  );
  var since = lastVisit == null ? fallback : dateOnly(lastVisit);
  if (since.isBefore(floor)) since = floor;

  final questions = <DevelopmentLog>[];
  final medicines = <DevelopmentLog>[];
  final sickDays = <DateTime>{};
  DevelopmentLog? lastMeasurement;
  double? maxTemperature;

  for (final log in logs) {
    if (log.type == LogType.question) {
      questions.add(log);
      continue;
    }

    if (log.type == LogType.measurement &&
        (log.metrics.weightKg != null || log.metrics.heightCm != null) &&
        !log.date.isAfter(today) &&
        (lastMeasurement == null || log.date.isAfter(lastMeasurement.date))) {
      lastMeasurement = log;
    }

    // Everything below is about the period, not about the whole diary.
    if (log.date.isBefore(since) || log.date.isAfter(today)) continue;

    if (log.type == LogType.note && log.title.trim() == LogTitles.medicine) {
      medicines.add(log);
    }
    if (log.type == LogType.illness) sickDays.add(dateOnly(log.date));

    final t = log.metrics.temperatureC;
    if (t != null && (maxTemperature == null || t > maxTemperature)) {
      maxTemperature = t;
    }
  }

  questions.sort((a, b) => a.date.compareTo(b.date));
  medicines.sort((a, b) => b.date.compareTo(a.date));

  final horizon = today.add(const Duration(days: visitVaccineHorizonDays));
  final vaccines =
      reminders
          .where(
            (r) =>
                r.type == ReminderType.vaccination &&
                !r.isCompleted &&
                r.scheduledTime.isBefore(horizon),
          )
          .toList()
        ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

  final foods = foodsIn(logs);

  return VisitPrep(
    now: today,
    since: since,
    lastVisit: lastVisit,
    ageMonths: child.ageInMonthsAt(today),
    questions: List.unmodifiable(questions),
    lastMeasurement: lastMeasurement,
    vaccines: List.unmodifiable(vaccines),
    newFoods: List.unmodifiable(
      foods.where((f) => !f.firstAt.isBefore(since)),
    ),
    watchedFoods: List.unmodifiable(
      foods.where((f) => f.isUnderWatchAt(today)),
    ),
    reactedFoods: List.unmodifiable(foods.where((f) => f.hadReaction)),
    medicines: List.unmodifiable(medicines),
    sickDays: sickDays.length,
    maxTemperature: maxTemperature,
  );
}