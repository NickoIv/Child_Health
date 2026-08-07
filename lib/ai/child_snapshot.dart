import '../core/analytics/daily_care.dart';
import '../core/analytics/illness_stats.dart';
import '../core/growth/who_standards.dart';
import '../core/vaccination/national_calendar.dart';
import '../models/child.dart';
import '../models/development_log.dart';
import '../models/json.dart';
import '../models/reminder.dart';

/// Everything the app already knows about this child, written out for the
/// prompt.
///
/// Until now the assistant was told a name, an age and a gender, and then
/// asked to answer questions about a child it knew nothing else about — while
/// the same screen the question was typed on showed six feeds, a nap and a
/// temperature. Every fact below is one the parent has already entered; none
/// of it is inferred, and none of it is a conclusion.
///
/// Written in Russian because it is prompt text, not interface: the model
/// answers in Russian and the knowledge base is Russian. It never reaches a
/// screen, so the localization rules do not apply to it.
///
/// Deliberately bounded. Everything here is either today, the last seven days
/// or the next two dates — a month of raw entries would push the articles the
/// answer must actually come from out of the model's attention.

/// How far back the weekly figures look.
const snapshotWeekDays = 7;

/// And how far back sick days are counted.
const snapshotIllnessDays = 30;

/// Longest the block is allowed to get. A guard, not a target: it is normally
/// a third of this.
const snapshotMaxChars = 1800;

/// The child's data as prompt lines, or null when there is nothing to say.
///
/// [now] is injectable so a test can pin "today" instead of racing the clock.
String childSnapshot({
  required Child child,
  List<DevelopmentLog> logs = const [],
  List<Reminder> reminders = const [],
  DateTime? now,
}) {
  final moment = now ?? DateTime.now();
  final lines = <String>[
    'Имя: ${child.name}, ${_gender(child)}, ${child.ageInMonthsAt(moment)} мес. '
        '(родился${child.gender == Gender.female ? 'ась' : 'ся'} '
        '${_date(child.birthDate)})',
  ];

  lines.addAll(_growthLines(child, logs, moment));
  lines.addAll(_todayLines(logs, moment));
  lines.addAll(_temperatureLines(logs, moment));
  lines.addAll(_weekLines(logs, moment));
  lines.addAll(_illnessLines(logs, moment));
  lines.addAll(_reminderLines(reminders, moment));

  if (lines.length == 1) {
    lines.add('Записей о кормлениях, сне и измерениях пока нет.');
  }

  final block = lines.join('\n');
  return block.length <= snapshotMaxChars
      ? block
      : '${block.substring(0, snapshotMaxChars)}…';
}

String _gender(Child child) =>
    child.gender == Gender.female ? 'девочка' : 'мальчик';

// --- Growth ---------------------------------------------------------------

/// The latest weight and height, each with its WHO percentile.
///
/// The percentile is scored against the child's age *on the day of the
/// measurement*, not today: a weight taken two months ago compared with
/// today's norms is a different child's number.
List<String> _growthLines(
  Child child,
  List<DevelopmentLog> logs,
  DateTime now,
) {
  final lines = <String>[];

  for (final metric in GrowthMetric.values) {
    DevelopmentLog? latest;
    for (final log in logs) {
      if (log.type != LogType.measurement || log.date.isAfter(now)) continue;
      final value = _metricValue(log, metric);
      if (value == null) continue;
      if (latest == null || log.date.isAfter(latest.date)) latest = log;
    }
    if (latest == null) continue;

    final value = _metricValue(latest, metric)!;
    final ageAt = child.ageInMonthsAt(latest.date);
    final z = zScore(metric, child.gender, ageAt, value);
    final reading = StringBuffer(
      '${metric.label}: $value ${metric.unit} (${_date(latest.date)}',
    );
    if (dateOnly(latest.date) != dateOnly(now)) {
      reading.write(', ${_daysAgo(latest.date, now)}');
    }
    reading.write(')');
    if (z != null) {
      reading.write(
        ', ${percentileFromZ(z).round()}-й перцентиль ВОЗ, '
        '${verdictFromZ(z).label.toLowerCase()}',
      );
    }
    lines.add(reading.toString());
  }

  return lines;
}

double? _metricValue(DevelopmentLog log, GrowthMetric metric) =>
    switch (metric) {
      GrowthMetric.weight => log.metrics.weightKg,
      GrowthMetric.height => log.metrics.heightCm,
    };

// --- Today ----------------------------------------------------------------

List<String> _todayLines(List<DevelopmentLog> logs, DateTime now) {
  final care = dailyCareFor(logs, now);
  if (care.isEmpty) return const [];

  final parts = <String>[];
  if (care.feedings > 0) {
    final last = care.lastFeedingAt;
    parts.add(
      last == null
          ? 'кормлений ${care.feedings}'
          : 'кормлений ${care.feedings} (последнее в ${_clock(last)}, '
                '${_duration(now.difference(last).inMinutes)} назад)',
    );
  }
  if (care.sleepMinutes > 0) {
    parts.add('сон ${_duration(care.sleepMinutes)} суммарно');
  }
  if (care.wetNappies > 0 || care.dirtyNappies > 0) {
    parts.add(
      'подгузники: мокрых ${care.wetNappies}, со стулом ${care.dirtyNappies}',
    );
  }
  return ['Сегодня: ${parts.join('; ')}'];
}

/// Every reading of the current day, and the highest of them.
///
/// The maximum matters more than the last one — a parent who gave paracetamol
/// at noon is asking about the 39.1 that made her give it.
List<String> _temperatureLines(List<DevelopmentLog> logs, DateTime now) {
  final today = dateOnly(now);
  double? highest;
  double? latest;
  DateTime? latestAt;

  for (final log in logs) {
    final t = log.metrics.temperatureC;
    if (t == null || log.date.isAfter(now)) continue;
    if (dateOnly(log.date) != today) continue;
    if (highest == null || t > highest) highest = t;
    if (latestAt == null || log.date.isAfter(latestAt)) {
      latestAt = log.date;
      latest = t;
    }
  }

  if (latest == null || latestAt == null) return const [];
  final line = StringBuffer(
    'Температура сегодня: $latest °C в ${_clock(latestAt)}',
  );
  if (highest != null && highest > latest) {
    line.write(', максимум за день $highest °C');
  }
  return [line.toString()];
}

// --- The week -------------------------------------------------------------

List<String> _weekLines(List<DevelopmentLog> logs, DateTime now) {
  final from = dateOnly(now).subtract(const Duration(days: snapshotWeekDays - 1));

  var feedings = 0;
  var nappies = 0;
  var sleep = 0;
  var bestNight = 0;
  final days = <DateTime>{};

  for (final log in logs) {
    if (log.date.isAfter(now) || log.date.isBefore(from)) continue;
    days.add(dateOnly(log.date));
    switch (log.type) {
      case LogType.feeding:
        feedings++;
      case LogType.nappy:
        nappies++;
      case LogType.sleep:
        sleep += log.durationMinutes ?? 0;
        if (log.isNightSleep && (log.durationMinutes ?? 0) > bestNight) {
          bestNight = log.durationMinutes!;
        }
      default:
        break;
    }
  }

  if (feedings == 0 && nappies == 0 && sleep == 0) return const [];

  // Averaged over the days that were actually written down, not over seven.
  // A mother who started keeping the diary on Friday has not been starving
  // anyone since Monday.
  final recorded = days.isEmpty ? 1 : days.length;
  final parts = <String>[
    if (feedings > 0) 'кормлений $feedings (≈${feedings ~/ recorded} в день)',
    if (sleep > 0) 'сон ≈${_duration(sleep ~/ recorded)} в сутки',
    if (nappies > 0) 'подгузников $nappies',
    if (bestNight > 0) 'самая длинная ночь ${_duration(bestNight)}',
  ];
  return ['За $snapshotWeekDays дней (записей за $recorded дн.): '
      '${parts.join('; ')}'];
}

// --- Illness --------------------------------------------------------------

List<String> _illnessLines(List<DevelopmentLog> logs, DateTime now) {
  final from = dateOnly(now).subtract(
    const Duration(days: snapshotIllnessDays - 1),
  );
  final byDay = worstSeverityByDay(logs)
    ..removeWhere((day, _) => day.isBefore(from) || day.isAfter(dateOnly(now)));
  if (byDay.isEmpty) return const [];

  final days = byDay.keys.toList()..sort();
  final last = days.last;
  return [
    'Дни болезни за последние $snapshotIllnessDays дн.: ${days.length} дн., '
        '${countIllnessEpisodes(byDay.keys.toSet())} эпизод(ов), '
        'последний ${_date(last)} (${byDay[last]!.label.toLowerCase()})',
  ];
}

// --- What is coming -------------------------------------------------------

List<String> _reminderLines(List<Reminder> reminders, DateTime now) {
  final lines = <String>[];

  final vaccinations = upcomingVaccinations(reminders, limit: 2, now: now);
  if (vaccinations.isNotEmpty) {
    lines.add(
      'Ближайшие прививки: '
      '${vaccinations.map((r) => '${_date(r.scheduledTime)} — ${r.title}').join('; ')}',
    );
  }

  // Anything else still open, overdue ones included: a dose that was missed
  // last week is exactly the kind of thing worth mentioning in an answer.
  final other =
      reminders
          .where(
            (r) => r.type != ReminderType.vaccination && !r.isCompleted,
          )
          .toList()
        ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  if (other.isNotEmpty) {
    lines.add(
      'Напоминания: '
      '${other.take(3).map((r) => '${_date(r.scheduledTime)} ${_clock(r.scheduledTime)} — ${r.title}').join('; ')}',
    );
  }

  return lines;
}

// --- Formatting -----------------------------------------------------------
// Hand-rolled rather than via intl: this text is Russian whatever locale the
// interface is in, and a fixed format is what makes the tests deterministic.

String _two(int value) => value.toString().padLeft(2, '0');

String _date(DateTime d) => '${_two(d.day)}.${_two(d.month)}.${d.year}';

String _clock(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

String _duration(int minutes) {
  if (minutes < 1) return 'меньше минуты';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return '$rest мин';
  if (rest == 0) return '$hours ч';
  return '$hours ч $rest мин';
}

String _daysAgo(DateTime at, DateTime now) {
  final days = dateOnly(now).difference(dateOnly(at)).inDays;
  if (days <= 0) return 'сегодня';
  if (days == 1) return 'вчера';
  return '$days дн. назад';
}
