import '../../models/child.dart';
import '../../models/reminder.dart';

/// One entry of the Russian national immunisation schedule
/// (национальный календарь профилактических прививок).
class VaccinationSlot {
  const VaccinationSlot(this.ageDays, this.name);

  /// Age at which the dose is due, in days from birth. Months are counted as
  /// 30 days and years as 365 — the schedule itself is specified in months,
  /// and parents adjust the exact date with their paediatrician anyway.
  final int ageDays;
  final String name;
}

const nationalVaccinationSchedule = <VaccinationSlot>[
  VaccinationSlot(1, 'Гепатит B — первая вакцинация'),
  VaccinationSlot(5, 'Туберкулёз (БЦЖ-М)'),
  VaccinationSlot(30, 'Гепатит B — вторая вакцинация'),
  VaccinationSlot(60, 'Пневмококковая инфекция — первая вакцинация'),
  VaccinationSlot(90, 'АКДС — первая вакцинация'),
  VaccinationSlot(90, 'Полиомиелит — первая вакцинация'),
  VaccinationSlot(90, 'Гемофильная инфекция — первая вакцинация'),
  VaccinationSlot(135, 'АКДС — вторая вакцинация'),
  VaccinationSlot(135, 'Полиомиелит — вторая вакцинация'),
  VaccinationSlot(135, 'Пневмококковая инфекция — вторая вакцинация'),
  VaccinationSlot(135, 'Гемофильная инфекция — вторая вакцинация'),
  VaccinationSlot(180, 'АКДС — третья вакцинация'),
  VaccinationSlot(180, 'Полиомиелит — третья вакцинация'),
  VaccinationSlot(180, 'Гепатит B — третья вакцинация'),
  VaccinationSlot(180, 'Гемофильная инфекция — третья вакцинация'),
  VaccinationSlot(360, 'Корь, краснуха, паротит'),
  VaccinationSlot(450, 'Пневмококковая инфекция — ревакцинация'),
  VaccinationSlot(540, 'АКДС — первая ревакцинация'),
  VaccinationSlot(540, 'Полиомиелит — первая ревакцинация'),
  VaccinationSlot(540, 'Гемофильная инфекция — ревакцинация'),
  VaccinationSlot(600, 'Полиомиелит — вторая ревакцинация'),
  VaccinationSlot(2190, 'Корь, краснуха, паротит — ревакцинация'),
  VaccinationSlot(2555, 'АДС-М — вторая ревакцинация'),
  VaccinationSlot(2555, 'Туберкулёз (БЦЖ) — ревакцинация'),
  VaccinationSlot(5110, 'АДС-М — третья ревакцинация'),
  VaccinationSlot(5110, 'Полиомиелит — третья ревакцинация'),
];

/// Builds the full immunisation plan for [child] as reminders.
///
/// Ids are left empty so the repository assigns them on insert. Doses already
/// due more than [gracePeriod] ago are marked completed, on the assumption
/// that a child enrolled mid-schedule has had the earlier ones — the parent
/// corrects any exceptions by hand.
List<Reminder> buildVaccinationPlan(
  Child child, {
  Duration gracePeriod = const Duration(days: 30),
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  return nationalVaccinationSchedule.map((slot) {
    final due = child.birthDate.add(Duration(days: slot.ageDays));
    return Reminder(
      id: '',
      childId: child.id,
      type: ReminderType.vaccination,
      title: slot.name,
      scheduledTime: due,
      isCompleted: due.isBefore(today.subtract(gracePeriod)),
      details: 'Национальный календарь профилактических прививок',
    );
  }).toList();
}

/// The next doses a parent should be aware of, soonest first.
List<Reminder> upcomingVaccinations(
  List<Reminder> reminders, {
  int limit = 5,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final upcoming =
      reminders
          .where(
            (r) =>
                r.type == ReminderType.vaccination &&
                !r.isCompleted &&
                r.scheduledTime.isAfter(today),
          )
          .toList()
        ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  return upcoming.take(limit).toList();
}
