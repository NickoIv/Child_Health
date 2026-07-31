import 'package:child_health_tracker/core/notifications/notification_plan.dart';
import 'package:child_health_tracker/models/reminder.dart';
import 'package:flutter_test/flutter_test.dart';

Reminder reminderAt(
  DateTime when, {
  String id = 'r1',
  Recurrence recurrence = Recurrence.none,
  bool isCompleted = false,
  String details = '',
  ReminderType type = ReminderType.medication,
}) => Reminder(
  id: id,
  childId: 'c1',
  type: type,
  title: 'Витамин D',
  scheduledTime: when,
  recurrence: recurrence,
  isCompleted: isCompleted,
  details: details,
);

void main() {
  // A Wednesday, so the weekly cases have an unambiguous weekday to land on.
  final now = DateTime(2026, 8, 5, 10, 0);

  group('notificationIdFor', () {
    test('is stable for the same reminder', () {
      expect(notificationIdFor('abc'), notificationIdFor('abc'));
    });

    test('separates the occurrences of one reminder', () {
      expect(notificationIdFor('abc', 0), isNot(notificationIdFor('abc', 1)));
    });

    test('separates different reminders', () {
      expect(notificationIdFor('abc'), isNot(notificationIdFor('abd')));
    });

    test('stays within the 32-bit range Android accepts', () {
      for (final id in ['abc', 'какое-то-длинное-имя', '9f2b1c', '']) {
        expect(notificationIdFor(id), inInclusiveRange(0, 0x7fffffff));
      }
    });
  });

  group('slotsFor', () {
    test('a one-off reminder in the future fires once', () {
      final slots = slotsFor(
        reminderAt(DateTime(2026, 8, 6, 9, 0)),
        now: now,
      );

      expect(slots, hasLength(1));
      expect(slots.single.when, DateTime(2026, 8, 6, 9, 0));
      expect(slots.single.repeat, RepeatRule.once);
    });

    test('a one-off reminder in the past fires never', () {
      final slots = slotsFor(
        reminderAt(DateTime(2026, 8, 4, 9, 0)),
        now: now,
      );

      expect(slots, isEmpty);
    });

    test('a completed reminder fires never', () {
      final slots = slotsFor(
        reminderAt(DateTime(2026, 8, 6, 9, 0), isCompleted: true),
        now: now,
      );

      expect(slots, isEmpty);
    });

    test('a daily reminder whose time has passed today starts tomorrow', () {
      final slots = slotsFor(
        reminderAt(DateTime(2026, 8, 1, 9, 0), recurrence: Recurrence.daily),
        now: now,
      );

      expect(slots, hasLength(1));
      expect(slots.single.when, DateTime(2026, 8, 6, 9, 0));
      expect(slots.single.repeat, RepeatRule.daily);
    });

    test('a daily reminder still to come today starts today', () {
      final slots = slotsFor(
        reminderAt(DateTime(2026, 8, 1, 21, 30), recurrence: Recurrence.daily),
        now: now,
      );

      expect(slots.single.when, DateTime(2026, 8, 5, 21, 30));
    });

    test('twice daily is two slots twelve hours apart', () {
      final slots = slotsFor(
        reminderAt(
          DateTime(2026, 8, 1, 8, 0),
          recurrence: Recurrence.twiceDaily,
        ),
        now: now,
      );

      expect(slots, hasLength(2));
      expect(slots[0].when, DateTime(2026, 8, 6, 8, 0));
      expect(slots[1].when, DateTime(2026, 8, 5, 20, 0));
      expect(slots.map((s) => s.repeat), everyElement(RepeatRule.daily));
      expect(slots[0].id, isNot(slots[1].id));
    });

    test('a weekly reminder lands on the same weekday', () {
      // 3 August 2026 is a Monday.
      final slots = slotsFor(
        reminderAt(DateTime(2026, 8, 3, 9, 0), recurrence: Recurrence.weekly),
        now: now,
      );

      expect(slots.single.when, DateTime(2026, 8, 10, 9, 0));
      expect(slots.single.when.weekday, DateTime.monday);
      expect(slots.single.repeat, RepeatRule.weekly);
    });

    test('the body falls back to the type when there are no details', () {
      final withDetails = slotsFor(
        reminderAt(DateTime(2026, 8, 6, 9, 0), details: '2 капли'),
        now: now,
      ).single;
      final without = slotsFor(
        reminderAt(DateTime(2026, 8, 6, 9, 0)),
        now: now,
      ).single;

      expect(withDetails.title, 'Витамин D');
      expect(withDetails.body, '2 капли');
      expect(without.body, ReminderType.medication.label);
    });
  });
}
