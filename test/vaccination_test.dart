import 'package:child_health_tracker/core/vaccination/national_calendar.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/reminder.dart';
import 'package:flutter_test/flutter_test.dart';

Child _childBorn(DateTime birth, {Gender gender = Gender.male}) => Child(
  id: 'c1',
  parentUid: 'p1',
  name: 'Тест',
  birthDate: birth,
  gender: gender,
);

void main() {
  group('buildVaccinationPlan', () {
    test('covers the whole schedule for a girl', () {
      final plan = buildVaccinationPlan(
        _childBorn(DateTime(2026, 1, 1), gender: Gender.female),
        now: DateTime(2026, 7, 25),
      );
      expect(plan, hasLength(nationalVaccinationSchedule.length));
      expect(plan.every((r) => r.type == ReminderType.vaccination), isTrue);
      expect(plan.every((r) => r.childId == 'c1'), isTrue);
    });

    test('omits the HPV doses for a boy', () {
      // The Kazakhstan schedule offers ВПЧ to girls only.
      final boys = buildVaccinationPlan(
        _childBorn(DateTime(2026, 1, 1)),
        now: DateTime(2026, 7, 25),
      );
      final girls = buildVaccinationPlan(
        _childBorn(DateTime(2026, 1, 1), gender: Gender.female),
        now: DateTime(2026, 7, 25),
      );
      expect(boys.where((r) => r.title.contains('ВПЧ')), isEmpty);
      expect(girls.where((r) => r.title.contains('ВПЧ')), hasLength(2));
      expect(boys.length, girls.length - 2);
    });

    test('schedules each dose relative to the birth date', () {
      final birth = DateTime(2026, 1, 1);
      final plan = buildVaccinationPlan(
        _childBorn(birth, gender: Gender.female),
        now: DateTime(2026, 1, 2),
      );
      for (var i = 0; i < plan.length; i++) {
        final expected = birth.add(
          Duration(days: nationalVaccinationSchedule[i].ageDays),
        );
        expect(plan[i].scheduledTime, expected);
      }
    });

    test('includes the Kazakhstan-specific entries', () {
      final plan = buildVaccinationPlan(
        _childBorn(DateTime(2026, 1, 1), gender: Gender.female),
        now: DateTime(2026, 7, 25),
      );
      final titles = plan.map((r) => r.title).join(' | ');
      // Hepatitis A is in the Kazakhstan calendar but not the Russian one —
      // a plain check that the right schedule is wired in.
      expect(titles, contains('Гепатит A'));
      expect(titles, contains('БЦЖ'));
      expect(titles, contains('Пентавакцина'));
      expect(titles, contains('ККП'));
      expect(titles, contains('АДС-М'));
    });

    test('marks long-past doses completed and future ones pending', () {
      final now = DateTime(2026, 7, 25);
      final plan = buildVaccinationPlan(
        _childBorn(DateTime(2025, 7, 25)),
        now: now,
      );
      final newborn = plan.firstWhere((r) => r.title.contains('БЦЖ'));
      final schoolAge = plan.firstWhere((r) => r.title.contains('АДС-М'));
      expect(newborn.isCompleted, isTrue);
      expect(schoolAge.isCompleted, isFalse);
    });

    test('a dose inside the grace period stays pending', () {
      final now = DateTime(2026, 7, 25);
      // Born 10 days ago: the day-3 dose is overdue but within the 30-day
      // grace period, so it must not be auto-marked as done.
      final plan = buildVaccinationPlan(
        _childBorn(now.subtract(const Duration(days: 10))),
        now: now,
      );
      final bcg = plan.firstWhere((r) => r.title.contains('БЦЖ'));
      expect(bcg.isCompleted, isFalse);
    });

    test('carries the schedule as the source in the details', () {
      final plan = buildVaccinationPlan(
        _childBorn(DateTime(2026, 1, 1)),
        now: DateTime(2026, 7, 25),
      );
      expect(
        plan.every((r) => r.details.contains('Календарь прививок РК')),
        isTrue,
      );
    });
  });

  group('upcomingVaccinations', () {
    test('returns only future, pending vaccinations, soonest first', () {
      final now = DateTime(2026, 7, 25);
      final reminders = [
        Reminder(
          id: '1',
          childId: 'c',
          type: ReminderType.vaccination,
          title: 'через 10 дней',
          scheduledTime: now.add(const Duration(days: 10)),
        ),
        Reminder(
          id: '2',
          childId: 'c',
          type: ReminderType.vaccination,
          title: 'через 2 дня',
          scheduledTime: now.add(const Duration(days: 2)),
        ),
        Reminder(
          id: '3',
          childId: 'c',
          type: ReminderType.vaccination,
          title: 'уже сделана',
          scheduledTime: now.add(const Duration(days: 5)),
          isCompleted: true,
        ),
        Reminder(
          id: '4',
          childId: 'c',
          type: ReminderType.appointment,
          title: 'не прививка',
          scheduledTime: now.add(const Duration(days: 1)),
        ),
        Reminder(
          id: '5',
          childId: 'c',
          type: ReminderType.vaccination,
          title: 'в прошлом',
          scheduledTime: now.subtract(const Duration(days: 3)),
        ),
      ];
      final upcoming = upcomingVaccinations(reminders, now: now);
      expect(upcoming.map((r) => r.title), ['через 2 дня', 'через 10 дней']);
    });

    test('honours the limit', () {
      final now = DateTime(2026, 7, 25);
      final reminders = [
        for (var i = 1; i <= 10; i++)
          Reminder(
            id: '$i',
            childId: 'c',
            type: ReminderType.vaccination,
            title: 'доза $i',
            scheduledTime: now.add(Duration(days: i)),
          ),
      ];
      expect(upcomingVaccinations(reminders, limit: 3, now: now), hasLength(3));
    });
  });
}
