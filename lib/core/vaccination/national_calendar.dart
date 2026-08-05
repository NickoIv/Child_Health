import '../../models/child.dart';
import '../../models/reminder.dart';

/// One entry of the Kazakhstan national immunisation schedule.
class VaccinationSlot {
  const VaccinationSlot(
    this.code,
    this.ageDays,
    this.name, {
    this.note = '',
  });

  /// Stable identifier for this dose, and the only thing the interface layer
  /// looks it up by. [name] and [note] are Russian because they are written
  /// into reminder documents and read back from ones written years ago; what
  /// a parent sees comes from the ARB, keyed by this.
  final String code;

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
  VaccinationSlot('hepB1', 1, 'Гепатит B (ВГВ) — первая доза', note: 'В первые сутки жизни'),
  VaccinationSlot('bcg', 3, 'Туберкулёз (БЦЖ)', note: 'На 1-4 сутки жизни'),
  VaccinationSlot('penta1', 60, 'Пентавакцина: АбКДС + Хиб + ВГВ + ИПВ — первая доза', note: 'Коклюш, дифтерия, столбняк, гемофильная инфекция, гепатит B, полиомиелит'),
  VaccinationSlot('pcv1', 60, 'Пневмококковая инфекция (ПНВ) — первая доза'),
  VaccinationSlot('penta2', 90, 'АбКДС + Хиб + ИПВ — вторая доза'),
  VaccinationSlot('penta3', 120, 'Пентавакцина: АбКДС + Хиб + ВГВ + ИПВ — третья доза'),
  VaccinationSlot('pcv2', 120, 'Пневмококковая инфекция (ПНВ) — вторая доза'),
  VaccinationSlot('mmr1', 365, 'Корь, краснуха, паротит (ККП) — первая доза', note: 'В 12-15 месяцев'),
  VaccinationSlot('pcvBooster', 365, 'Пневмококковая инфекция (ПНВ) — ревакцинация'),
  VaccinationSlot('opv', 365, 'Полиомиелит (ОПВ)'),
  VaccinationSlot('pentaBooster', 540, 'АбКДС + Хиб + ИПВ — ревакцинация', note: 'В 18 месяцев'),
  VaccinationSlot('hepA1', 730, 'Гепатит A (ВГА) — первая доза', note: 'В 2 года'),
  VaccinationSlot('hepA2', 912, 'Гепатит A (ВГА) — вторая доза', note: 'Через 6 месяцев'),
  VaccinationSlot('dtapBooster', 2190, 'АбКДС — ревакцинация', note: 'В 6 лет, перед школой'),
  VaccinationSlot('mmr2', 2190, 'Корь, краснуха, паротит (ККП) — вторая доза'),
  VaccinationSlot('hpv1', 4015, 'ВПЧ — первая доза (девочки)', note: 'В 11 лет, по согласию родителей'),
  VaccinationSlot('hpv2', 4197, 'ВПЧ — вторая доза (девочки)', note: 'Через 6 месяцев'),
  VaccinationSlot('tdBooster', 5840, 'АДС-М — ревакцинация', note: 'В 16 лет, далее каждые 10 лет'),
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
    if (slot.code.startsWith('hpv')) return child.gender == Gender.female;
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

/// The phrase every scheduled dose carries, so a reminder from the national
/// plan is recognisable however old the document is.
const vaccinationSourceMarker = 'Календарь прививок РК';

/// Which slot a stored reminder name came from, or null if a parent wrote it.
String? vaccinationCodeFor(String storedName) {
  for (final slot in nationalVaccinationSchedule) {
    if (slot.name == storedName) return slot.code;
  }
  return null;
}

/// And the same for the note the plan stored under it.
String? vaccinationCodeForNote(String storedNote) {
  for (final slot in nationalVaccinationSchedule) {
    if (slot.note.isNotEmpty && slot.note == storedNote) return slot.code;
  }
  return null;
}
