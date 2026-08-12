import '../core/analytics/daily_care.dart';
import '../core/care/sleep_forecast.dart';
import '../core/care/solids.dart';
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

/// How many of the next vaccinations are named.
///
/// Four rather than two. «Что нас ждёт до года» is one of the questions this
/// app exists for, and two doses is the next month — which the reminders
/// screen already shows her.
const snapshotVaccinationCount = 4;

/// Days of entries a past week needs before it is worth comparing with.
///
/// Five out of seven. A week with two days in it is not a quieter month, it
/// is a month nobody was writing in, and calling that a change would invent
/// one out of a gap in the diary.
const snapshotComparableDays = 5;

/// How many recently introduced foods are named.
///
/// Three. The question a parent asks about food is almost always about the
/// last thing tried — «его обсыпало, это от чего?» — and the answer to that is
/// in the last few days, not in the porridge from March. Everything older is
/// still in the medical card, where a doctor reads it.
const snapshotFoodCount = 3;

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
        // «родилась» / «родился» — the stem is «родил», and it used to be
        // «родился» with the feminine ending stuck on the end of it.
        '(родил${child.gender == Gender.female ? 'ась' : 'ся'} '
        '${_date(child.birthDate)})',
  ];

  lines.addAll(_growthLines(child, logs, moment));
  lines.addAll(_todayLines(logs, moment));
  lines.addAll(_temperatureLines(logs, moment));
  lines.addAll(_sleepWindowLines(child, logs, moment));
  lines.addAll(_weekLines(logs, moment));
  lines.addAll(_illnessLines(logs, moment));
  lines.addAll(_solidsLines(logs, moment));
  lines.addAll(_reminderLines(reminders, moment));

  if (lines.length == 1) {
    lines.add('Записей о кормлениях, сне и измерениях пока нет.');
  }

  return _withinBudget(lines);
}

/// The block, cut at a line boundary if it has to be cut at all.
///
/// It used to be `substring(0, snapshotMaxChars)`, which cuts wherever the
/// character count lands — mid-word, mid-number. A model handed «последняя
/// температура 37.» reads a fact that is not true, and half a figure is worse
/// than no figure, because there is nothing about it that looks broken.
///
/// Whole lines only, from the end: what comes first here is who the child is
/// and what happened today, and what comes last is the furthest from the
/// question being asked.
String _withinBudget(List<String> lines) {
  final buffer = StringBuffer();
  var used = 0;

  for (final line in lines) {
    // The newline this line would bring with it, except for the first.
    final cost = line.length + (used == 0 ? 0 : 1);
    if (used + cost > snapshotMaxChars) break;
    if (used > 0) buffer.write('\n');
    buffer.write(line);
    used += cost;
  }

  return buffer.toString();
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

// --- Sleep window ---------------------------------------------------------

/// How long he is usually awake, and when the current stretch started.
///
/// Here so that «когда он захочет спать» is answered from his own fortnight
/// rather than from the model's memory of a sleep book. The line says which of
/// the two the figure came from, so the assistant can pass that on instead of
/// presenting an age norm as an observation about this child.
List<String> _sleepWindowLines(
  Child child,
  List<DevelopmentLog> logs,
  DateTime now,
) {
  final months = child.ageInMonthsAt(now);
  if (months > forecastMaxAgeMonths) return const [];

  // Nothing at all until one sleep has been written down. The age table would
  // print a window for a child nobody has recorded anything about, and the
  // snapshot's job is to say what is known — «записей пока нет» is the honest
  // line for that case, and a wake window on top of it would contradict it.
  final awakeSince = lastWakingAt(logs, now);
  if (awakeSince == null) return const [];

  final window = wakeWindowFor(logs, now, ageMonths: months);
  final source = window.samples >= minForecastSamples
      ? 'по ${window.samples} промежуткам за $forecastHistoryDays дней'
      : 'по возрастным нормам, своих записей пока мало';
  final line = StringBuffer(
    'Окно бодрствования: ≈${window.minutes} мин ($source)',
  );

  final awake = now.difference(awakeSince).inMinutes;
  // The current stretch only while it is still today's. Yesterday's last nap
  // says nothing about this afternoon, and printing it invites the model to do
  // arithmetic on a stale number.
  if (awake >= 0 && awake <= 12 * 60) {
    final expected = awakeSince.add(Duration(minutes: window.minutes));
    line.write(
      '. Не спит с ${_clock(awakeSince)} ($awake мин), '
      'следующий сон ориентировочно ${_clock(expected)}',
    );
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
  return [
    'За $snapshotWeekDays дней (записей за $recorded дн.): ${parts.join('; ')}',
    ..._monthAgoLines(logs, now, feedings ~/ recorded, sleep ~/ recorded),
  ];
}

/// The same week, a month earlier.
///
/// «Он стал есть меньше?» could not be answered before: the assistant saw
/// this week and nothing behind it, so every question about a change was
/// answered with a description of the present. This is the comparison a
/// parent is actually making in her head, and she is making it against a
/// memory rather than against a count.
///
/// Only when there is something to compare with — five days of entries in
/// that week, out of seven. Fewer is not a quieter month, it is a month
/// nobody was writing in, and calling that a drop would invent a change out
/// of a gap in the diary.
List<String> _monthAgoLines(
  List<DevelopmentLog> logs,
  DateTime now,
  int feedingsNow,
  int sleepNow,
) {
  final end = dateOnly(now).subtract(const Duration(days: 28));
  final start = end.subtract(const Duration(days: snapshotWeekDays - 1));

  var feedings = 0;
  var sleep = 0;
  final days = <DateTime>{};

  for (final log in logs) {
    final on = dateOnly(log.date);
    if (on.isBefore(start) || on.isAfter(end)) continue;
    days.add(on);
    if (log.type == LogType.feeding) feedings++;
    if (log.type == LogType.sleep) sleep += log.durationMinutes ?? 0;
  }

  if (days.length < snapshotComparableDays) return const [];

  final was = <String>[
    if (feedings > 0) 'кормлений ≈${feedings ~/ days.length} в день',
    if (sleep > 0) 'сон ≈${_duration(sleep ~/ days.length)} в сутки',
  ];
  if (was.isEmpty) return const [];

  // Stated as two figures side by side rather than as a verdict: «стало
  // меньше» is a conclusion, and which way is good depends on the age, the
  // week and the child.
  return [
    'Месяц назад за такую же неделю: ${was.join('; ')} '
        '(сейчас ≈$feedingsNow кормлений в день, '
        'сон ≈${_duration(sleepNow)} в сутки)',
  ];
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

// --- Solids ---------------------------------------------------------------

/// What has been introduced lately, what is still being watched, and what
/// there was a reaction to.
///
/// This block was missing entirely, and it is the one a parent asks about by
/// name: «его обсыпало», «он это раньше не ел». The assistant was answering
/// those with no idea what the child had eaten, off a screen where the
/// courgette from Tuesday was written down two taps away.
///
/// The reactions line is the important one. Without it the model is left to
/// guess which food a rash belongs to, and it will guess — with it, the guess
/// is already made, by the parent, and the answer can be about what to do.
List<String> _solidsLines(List<DevelopmentLog> logs, DateTime now) {
  final foods = foodsIn(logs);
  if (foods.isEmpty) return const [];

  final lines = <String>[];

  final recent = foods
      .take(snapshotFoodCount)
      .map((f) => '${f.name} (${_date(f.firstAt)})')
      .join(', ');
  lines.add('Прикорм: введено ${foods.length}, последние — $recent');

  final watched = foods.where((f) => f.isUnderWatchAt(now)).toList();
  if (watched.isNotEmpty) {
    lines.add(
      'Под наблюдением ($newFoodWatchDays дн. после первой ложки): '
      '${watched.map((f) => f.name).join(', ')}',
    );
  }

  // Her own words, not a severity: what she wrote is the observation, and
  // paraphrasing it into a category would lose the only detail that matters.
  final reacted = foods.where((f) => f.hadReaction).toList();
  if (reacted.isNotEmpty) {
    lines.add(
      'Была реакция: '
      '${reacted.map((f) => '${f.name} — ${f.reactions.first.description.trim()}').join('; ')}',
    );
  }

  return lines;
}

// --- What is coming -------------------------------------------------------

List<String> _reminderLines(List<Reminder> reminders, DateTime now) {
  final lines = <String>[];

  final vaccinations = upcomingVaccinations(
    reminders,
    limit: snapshotVaccinationCount,
    now: now,
  );
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
