import '../../models/reminder.dart';

/// How a scheduled notification repeats, stated without reference to any
/// plugin so this file stays testable on its own.
enum RepeatRule { once, daily, weekly }

/// One notification the operating system should be holding for a reminder.
class NotificationSlot {
  const NotificationSlot({
    required this.id,
    required this.title,
    required this.body,
    required this.when,
    required this.repeat,
  });

  final int id;
  final String title;
  final String body;

  /// First — and for [RepeatRule.once], only — time it fires. Always in the
  /// future relative to the `now` it was computed against.
  final DateTime when;

  final RepeatRule repeat;
}

/// Stable notification id for a reminder.
///
/// Android and iOS index notifications by 32-bit int, while a [Reminder] is
/// keyed by a Firestore string. Hashing bridges the two: the same reminder
/// always lands on the same id, so rescheduling replaces rather than
/// duplicates. [occurrence] separates the slots of a reminder that fires more
/// than once a day.
int notificationIdFor(String reminderId, [int occurrence = 0]) =>
    '$reminderId#$occurrence'.hashCode & 0x7fffffff;

/// Every notification that should exist for [reminder] as of [now].
///
/// Returns nothing for a reminder that is done or whose single moment has
/// passed — the caller cancels by id regardless, so an empty list is the
/// instruction to hold nothing.
List<NotificationSlot> slotsFor(Reminder reminder, {DateTime? now}) {
  if (reminder.isCompleted) return const [];

  final at = reminder.scheduledTime;
  final moment = now ?? DateTime.now();
  final title = reminder.title;
  final body = reminder.details.isNotEmpty
      ? reminder.details
      : reminder.type.label;

  NotificationSlot slot(int occurrence, DateTime when, RepeatRule repeat) =>
      NotificationSlot(
        id: notificationIdFor(reminder.id, occurrence),
        title: title,
        body: body,
        when: when,
        repeat: repeat,
      );

  switch (reminder.recurrence) {
    case Recurrence.none:
      // A vaccination that was due last week is the planner's problem, not
      // the notification system's: firing it now would only confuse.
      if (!at.isAfter(moment)) return const [];
      return [slot(0, at, RepeatRule.once)];

    case Recurrence.daily:
      return [slot(0, _nextDailyAt(at, moment), RepeatRule.daily)];

    case Recurrence.twiceDaily:
      final second = _shiftedByHalfDay(at);
      return [
        slot(0, _nextDailyAt(at, moment), RepeatRule.daily),
        slot(1, _nextDailyAt(second, moment), RepeatRule.daily),
      ];

    case Recurrence.weekly:
      return [slot(0, _nextWeeklyAt(at, moment), RepeatRule.weekly)];
  }
}

/// Next time today or tomorrow that matches the hour and minute of [at].
///
/// Rebuilt from calendar fields rather than by adding a [Duration] so that a
/// daylight-saving change moves the wall clock, not the alarm.
DateTime _nextDailyAt(DateTime at, DateTime now) {
  final today = DateTime(now.year, now.month, now.day, at.hour, at.minute);
  if (today.isAfter(now)) return today;
  return DateTime(now.year, now.month, now.day + 1, at.hour, at.minute);
}

/// Next time matching both the weekday and the time of [at].
DateTime _nextWeeklyAt(DateTime at, DateTime now) {
  var next = _nextDailyAt(at, now);
  while (next.weekday != at.weekday) {
    next = DateTime(next.year, next.month, next.day + 1, at.hour, at.minute);
  }
  return next;
}

/// The same clock time twelve hours later, wrapped within the day.
DateTime _shiftedByHalfDay(DateTime at) =>
    DateTime(at.year, at.month, at.day, at.hour + 12, at.minute);
