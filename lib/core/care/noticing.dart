import '../../models/child.dart';
import '../../models/development_log.dart';
import '../../models/json.dart';

/// Something true about today, or nothing at all.
///
/// The card at the top of the home screen has been carrying a phrase of the
/// day: six sentences on a rotation, shown whatever happened. Six sentences
/// are enough to be kind on the first morning and not enough to still mean
/// anything on the twentieth — by then it is wallpaper, and on a bad day it
/// reads as an app that is not looking.
///
/// This is the other half of that card. It says something only when there is
/// something true to say, and the phrase of the day is what shows when there
/// is not. Two rules hold it there:
///
/// **It is a fact, not an assessment.** «Сегодня ровно четыре месяца» is a
/// date. «Вы хорошо справляетесь» is an opinion about her, and an opinion
/// repeated on a schedule stops being worth anything.
///
/// **Nothing here can be missed.** There is deliberately no streak, no run of
/// days, no "you have recorded everything for a week" — a streak is an
/// obligation, and an obligation is the last thing to hand a mother who has
/// been awake since four. Everything below is either a date that arrives on
/// its own or a piece of good news about a night that already happened.
enum NoticedKind {
  /// The child is an exact number of months old today.
  roundAge,

  /// Last night was the longest in a month.
  longestNight,
}

class Noticed {
  const Noticed._(this.kind, {this.months = 0, this.minutes = 0});

  final NoticedKind kind;

  /// Whole months, for [NoticedKind.roundAge].
  final int months;

  /// How long the night ran, for [NoticedKind.longestNight].
  final int minutes;
}

/// A night has to beat this many other nights before it is worth a sentence.
///
/// Five, so the claim is about a habit and not about the two nights that
/// happen to be written down. Below it the app says nothing, which on a
/// freshly installed app is most of the first week.
const _minNightsToCompare = 5;

/// How far back "in a month" reaches.
const _nightWindowDays = 30;

/// And how much longer the night has to be before anyone would have noticed.
///
/// Twenty minutes. A night that beat the last four weeks by six minutes is a
/// rounding difference dressed up as good news, and a mother who reads it and
/// does not recognise her own night stops believing the next one.
const _nightMarginMinutes = 20;

/// The one thing worth saying today, or null.
///
/// [now] rather than a clock read inside, so the whole of this file is
/// testable and so the sentence changes at midnight rather than whenever the
/// widget happens to rebuild.
Noticed? noticedFor(Child child, List<DevelopmentLog> logs, DateTime now) {
  // The date first: it comes round twelve times a year, it cannot be inferred
  // from anything else on the screen, and it is the one a mother tells other
  // people about.
  final months = _exactMonthsToday(child.birthDate, now);
  if (months != null) return Noticed._(NoticedKind.roundAge, months: months);

  final minutes = _longestNightJustEnded(logs, now);
  if (minutes != null) {
    return Noticed._(NoticedKind.longestNight, minutes: minutes);
  }

  return null;
}

/// Whole months old today, or null on any other day.
///
/// Returns null for the day itself and for the first month: a newborn is
/// measured in days by everyone around her, and «ровно 0 месяцев» is not a
/// sentence anybody says.
int? _exactMonthsToday(DateTime birth, DateTime now) {
  final today = dateOnly(now);
  final born = dateOnly(birth);
  if (!today.isAfter(born)) return null;

  var months = (today.year - born.year) * 12 + today.month - born.month;
  if (today.day < born.day) months--;
  if (months < 1) return null;

  // The anniversary day, clamped into a month that may be shorter than the
  // one the child was born in. Born on the 31st, she turns a month old on the
  // 30th of April — the alternative is a birthday that silently skips every
  // second month.
  final lastOfThisMonth = DateTime(today.year, today.month + 1, 0).day;
  final anniversary = born.day > lastOfThisMonth ? lastOfThisMonth : born.day;

  return today.day == anniversary ? months : null;
}

/// The length of last night, if it beat the month before it, else null.
///
/// Morning only. By the afternoon the night is two meals ago and saying it
/// then is the app catching up rather than noticing.
int? _longestNightJustEnded(List<DevelopmentLog> logs, DateTime now) {
  if (now.hour >= 12) return null;

  DevelopmentLog? last;
  final earlier = <int>[];

  for (final log in logs) {
    if (!log.isNightSleep || log.date.isAfter(now)) continue;
    final minutes = log.durationMinutes ?? 0;
    if (minutes <= 0) continue;

    // A night is dated to the evening it began, so the one this morning
    // belongs to was written down yesterday.
    if (now.difference(log.date).inHours <= 24) {
      if (last == null || log.date.isAfter(last.date)) {
        if (last != null) earlier.add(last.durationMinutes ?? 0);
        last = log;
        continue;
      }
    }
    if (now.difference(log.date).inDays > _nightWindowDays) continue;
    earlier.add(minutes);
  }

  if (last == null || earlier.length < _minNightsToCompare) return null;

  final best = earlier.reduce((a, b) => a > b ? a : b);
  final minutes = last.durationMinutes ?? 0;
  return minutes >= best + _nightMarginMinutes ? minutes : null;
}
