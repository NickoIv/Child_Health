import 'json.dart';

enum ReminderType {
  vaccination('vaccination', 'Прививка'),
  medication('medication', 'Лекарство'),
  appointment('appointment', 'Визит к врачу');

  const ReminderType(this.code, this.label);

  final String code;
  final String label;

  static ReminderType fromCode(String? code) => ReminderType.values.firstWhere(
    (t) => t.code == code,
    orElse: () => ReminderType.appointment,
  );
}

/// How often a reminder repeats. `none` covers one-off events such as a
/// scheduled vaccination or a single doctor's appointment.
enum Recurrence {
  none('none', 'Однократно'),
  daily('daily', 'Ежедневно'),
  twiceDaily('twice_daily', 'Дважды в день'),
  weekly('weekly', 'Еженедельно');

  const Recurrence(this.code, this.label);

  final String code;
  final String label;

  static Recurrence fromCode(String? code) => Recurrence.values.firstWhere(
    (r) => r.code == code,
    orElse: () => Recurrence.none,
  );
}

/// An entry in collection `reminders`.
class Reminder {
  const Reminder({
    required this.id,
    required this.childId,
    required this.type,
    required this.title,
    required this.scheduledTime,
    this.recurrence = Recurrence.none,
    this.isCompleted = false,
    this.details = '',
  });

  final String id;
  final String childId;
  final ReminderType type;
  final String title;
  final DateTime scheduledTime;
  final Recurrence recurrence;
  final bool isCompleted;

  /// Dosage for medication, specialist and place for an appointment.
  final String details;

  bool get isOverdue =>
      !isCompleted && scheduledTime.isBefore(DateTime.now());

  int get daysUntil =>
      dateOnly(scheduledTime).difference(dateOnly(DateTime.now())).inDays;

  Reminder copyWith({
    ReminderType? type,
    String? title,
    DateTime? scheduledTime,
    Recurrence? recurrence,
    bool? isCompleted,
    String? details,
  }) {
    return Reminder(
      id: id,
      childId: childId,
      type: type ?? this.type,
      title: title ?? this.title,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      recurrence: recurrence ?? this.recurrence,
      isCompleted: isCompleted ?? this.isCompleted,
      details: details ?? this.details,
    );
  }

  Map<String, dynamic> toMap() => {
    'child_id': childId,
    'type': type.code,
    'title': title,
    'scheduled_time': scheduledTime.toIso8601String(),
    'recurrence': recurrence.code,
    'is_completed': isCompleted,
    'details': details,
  };

  factory Reminder.fromMap(String id, Map<String, dynamic> map) {
    return Reminder(
      id: id,
      childId: map['child_id'] as String? ?? '',
      type: ReminderType.fromCode(map['type'] as String?),
      title: map['title'] as String? ?? '',
      scheduledTime: parseDate(map['scheduled_time']) ?? DateTime.now(),
      recurrence: Recurrence.fromCode(map['recurrence'] as String?),
      isCompleted: map['is_completed'] as bool? ?? false,
      details: map['details'] as String? ?? '',
    );
  }
}
