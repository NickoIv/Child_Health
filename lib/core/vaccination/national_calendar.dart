import '../../models/child.dart';
import '../../models/reminder.dart';

/// One entry of the Kazakhstan national immunisation schedule.
class VaccinationSlot {
  const VaccinationSlot(this.ageDays, this.name, {this.note = ''});

  /// Age at which the dose is due, in days from birth. Months are counted as
  /// 30 days and years as 365 — the schedule is written in months, and the
  /// exact date is agreed with the paediatrician anyway.
  final int ageDays;
  final String name;
  final String note;
}

/// Национальный календарь профилактических прививок Республики Казахстан.
///
/// Основание: Постановление Правительства РК от 24 сентября 2020 года № 612
/// «Об утверждении перечня заболеваний, против которых проводятся обязательные
/// профилактические прививки...». Прививки в рамках ГОБМП — бесплатны.
///
/// ВНИМАНИЕ: перед выпуском список нужно сверить с действующей редакцией
/// постановления — календарь пересматривается. В частности, ревакцинация БЦЖ
/// в 6-7 лет присутствовала в более старых редакциях и здесь не приводится.
const nationalVaccinationSchedule = <VaccinationSlot>[
  VaccinationSlot(1, 'Гепатит B (ВГВ) — первая доза', note: 'В первые сутки жизни'),
  VaccinationSlot(3, 'Туберкулёз (БЦЖ)', note: 'На 1-4 сутки жизни'),
  VaccinationSlot(
    60,
    'Пентавакцина: АбКДС + Хиб + ВГВ + ИПВ — первая доза',
    note: 'Коклюш, дифтерия, столбняк, гемофильная инфекция, гепатит B, полиомиелит',
  ),
  VaccinationSlot(60, 'Пневмококковая инфекция (ПНВ) — первая доза'),
  VaccinationSlot(90, 'АбКДС + Хиб + ИПВ — вторая доза'),
  VaccinationSlot(
    120,
    'Пентавакцина: АбКДС + Хиб + ВГВ + ИПВ — третья доза',
  ),
  VaccinationSlot(120, 'Пневмококковая инфекция (ПНВ) — вторая доза'),
  VaccinationSlot(365, 'Корь, краснуха, паротит (ККП) — первая доза',
      note: 'В 12-15 месяцев'),
  VaccinationSlot(365, 'Пневмококковая инфекция (ПНВ) — ревакцинация'),
  VaccinationSlot(365, 'Полиомиелит (ОПВ)'),
  VaccinationSlot(540, 'АбКДС + Хиб + ИПВ — ревакцинация', note: 'В 18 месяцев'),
  VaccinationSlot(730, 'Гепатит A (ВГА) — первая доза', note: 'В 2 года'),
  VaccinationSlot(912, 'Гепатит A (ВГА) — вторая доза', note: 'Через 6 месяцев'),
  VaccinationSlot(2190, 'АбКДС — ревакцинация', note: 'В 6 лет, перед школой'),
  VaccinationSlot(2190, 'Корь, краснуха, паротит (ККП) — вторая доза'),
  VaccinationSlot(
    4015,
    'ВПЧ — первая доза (девочки)',
    note: 'В 11 лет, по согласию родителей',
  ),
  VaccinationSlot(4197, 'ВПЧ — вторая доза (девочки)', note: 'Через 6 месяцев'),
  VaccinationSlot(
    5840,
    'АДС-М — ревакцинация',
    note: 'В 16 лет, далее каждые 10 лет',
  ),
];

/// Builds the immunisation plan for [child] as reminders.
///
/// Ids are left empty so the repository assigns them on insert. Doses due more
/// than [gracePeriod] ago are marked completed, on the assumption that a child
/// enrolled mid-schedule has had the earlier ones — the parent corrects any
/// exceptions by hand.
List<Reminder> buildVaccinationPlan(
  Child child, {
  Duration gracePeriod = const Duration(days: 30),
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  return nationalVaccinationSchedule.where((slot) {
    // HPV is offered to girls only.
    if (slot.name.contains('ВПЧ')) return child.gender == Gender.female;
    return true;
  }).map((slot) {
    final due = child.birthDate.add(Duration(days: slot.ageDays));
    return Reminder(
      id: '',
      childId: child.id,
      type: ReminderType.vaccination,
      title: slot.name,
      scheduledTime: due,
      isCompleted: due.isBefore(today.subtract(gracePeriod)),
      // Both branches end with the same phrase so the source is always
      // recognisable in the reminder list.
      details: slot.note.isEmpty
          ? 'Календарь прививок РК'
          : '${slot.note} · Календарь прививок РК',
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
