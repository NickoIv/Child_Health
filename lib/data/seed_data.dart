import 'package:uuid/uuid.dart';

import '../core/vaccination/national_calendar.dart';
import '../models/child.dart';
import '../models/development_log.dart';
import '../models/medical_record.dart';
import '../models/reminder.dart';

const _uuid = Uuid();

class SeedData {
  const SeedData({
    required this.children,
    required this.logs,
    required this.records,
    required this.reminders,
  });

  final List<Child> children;
  final List<DevelopmentLog> logs;
  final List<MedicalRecord> records;
  final List<Reminder> reminders;
}

/// Demo content so the app has something to show before Firebase is wired in.
///
/// Ages are computed backwards from today, so the growth chart always spans a
/// sensible range no matter when the app is opened.
SeedData buildSeedData(String parentUid) {
  final today = DateTime.now();
  final birthDate = DateTime(today.year - 1, today.month, today.day - 60);

  final child = Child(
    id: _uuid.v4(),
    parentUid: parentUid,
    name: 'Демо-профиль',
    birthDate: birthDate,
    gender: Gender.male,
  );

  final logs = <DevelopmentLog>[
    ..._measurements(child, birthDate),
    DevelopmentLog(
      id: _uuid.v4(),
      childId: child.id,
      date: birthDate.add(const Duration(days: 190)),
      type: LogType.milestone,
      title: 'Первый зуб',
      description: 'Нижний резец слева.',
      tags: const ['зубы'],
    ),
    DevelopmentLog(
      id: _uuid.v4(),
      childId: child.id,
      date: birthDate.add(const Duration(days: 240)),
      type: LogType.milestone,
      title: 'Сел самостоятельно',
      description: 'Уверенно сидит без опоры больше минуты.',
      tags: const ['моторика'],
    ),
    DevelopmentLog(
      id: _uuid.v4(),
      childId: child.id,
      date: birthDate.add(const Duration(days: 330)),
      type: LogType.milestone,
      title: 'Первое слово',
      description: '«Мама», осознанно и по адресу.',
      tags: const ['речь'],
    ),
    for (var i = 0; i < 4; i++)
      DevelopmentLog(
        id: _uuid.v4(),
        childId: child.id,
        date: today.subtract(Duration(days: 45 + i)),
        type: LogType.illness,
        title: 'ОРВИ',
        description: i == 0
            ? 'Температура 37.8, насморк.'
            : 'Температура спадает, остаётся насморк.',
        severity: i < 2 ? Severity.moderate : Severity.mild,
        tags: const ['ОРВИ'],
      ),
    for (var i = 0; i < 2; i++)
      DevelopmentLog(
        id: _uuid.v4(),
        childId: child.id,
        date: today.subtract(Duration(days: 12 + i)),
        type: LogType.illness,
        title: 'Прорезывание зубов',
        description: 'Беспокойный сон, температура 37.2.',
        severity: Severity.mild,
        tags: const ['зубы'],
      ),
  ];

  final records = <MedicalRecord>[
    MedicalRecord(
      id: _uuid.v4(),
      childId: child.id,
      date: today.subtract(const Duration(days: 40)),
      diagnosis: 'ОРВИ, неосложнённое течение',
      prescriptions: 'Обильное питьё, промывание носа физраствором. '
          'Жаропонижающее при температуре выше 38.5.',
      doctor: 'Педиатр, поликлиника по месту жительства',
      labResults: const [
        LabResult(
          name: 'Гемоглобин',
          value: 118,
          unit: 'г/л',
          referenceMin: 110,
          referenceMax: 140,
        ),
        LabResult(
          name: 'Лейкоциты',
          value: 12.4,
          unit: '10⁹/л',
          referenceMin: 6,
          referenceMax: 12,
        ),
        LabResult(
          name: 'СОЭ',
          value: 14,
          unit: 'мм/ч',
          referenceMin: 2,
          referenceMax: 12,
        ),
      ],
    ),
  ];

  final reminders = <Reminder>[
    ...buildVaccinationPlan(child, now: today).map(_withId),
    Reminder(
      id: _uuid.v4(),
      childId: child.id,
      type: ReminderType.appointment,
      title: 'Плановый осмотр педиатра',
      scheduledTime: today.add(const Duration(days: 9)),
      details: 'Поликлиника, кабинет 210',
    ),
    Reminder(
      id: _uuid.v4(),
      childId: child.id,
      type: ReminderType.medication,
      title: 'Витамин D',
      scheduledTime: DateTime(today.year, today.month, today.day, 9),
      recurrence: Recurrence.daily,
      details: '500 МЕ, одна капля утром',
    ),
  ];

  return SeedData(
    children: [child],
    logs: logs,
    records: records,
    reminders: reminders,
  );
}

Reminder _withId(Reminder r) => Reminder(
  id: _uuid.v4(),
  childId: r.childId,
  type: r.type,
  title: r.title,
  scheduledTime: r.scheduledTime,
  recurrence: r.recurrence,
  isCompleted: r.isCompleted,
  details: r.details,
);

/// Measurements roughly following the WHO median, with a little noise so the
/// chart does not look synthetic.
List<DevelopmentLog> _measurements(Child child, DateTime birthDate) {
  const points = <(int, double, double)>[
    (0, 3.4, 50.0),
    (1, 4.5, 54.8),
    (2, 5.7, 58.5),
    (3, 6.5, 61.6),
    (4, 7.1, 63.9),
    (6, 8.0, 67.8),
    (8, 8.6, 70.6),
    (10, 9.2, 73.4),
    (12, 9.8, 76.1),
  ];
  final today = DateTime.now();
  return [
    for (final (month, weight, height) in points)
      if (birthDate
          .add(Duration(days: month * 30))
          .isBefore(today))
        DevelopmentLog(
          id: _uuid.v4(),
          childId: child.id,
          date: birthDate.add(Duration(days: month * 30)),
          type: LogType.measurement,
          title: 'Плановое измерение',
          metrics: Metrics(weightKg: weight, heightCm: height),
        ),
  ];
}
