import 'json.dart';

enum LogType {
  milestone('milestone', 'Веха развития'),
  measurement('measurement', 'Измерение'),
  illness('illness', 'Болезнь'),
  note('note', 'Запись');

  const LogType(this.code, this.label);

  final String code;
  final String label;

  static LogType fromCode(String? code) => LogType.values.firstWhere(
    (t) => t.code == code,
    orElse: () => LogType.note,
  );
}

/// Severity of an illness episode, used by the illness heat map.
enum Severity {
  mild('mild', 'Лёгкая'),
  moderate('moderate', 'Средняя'),
  severe('severe', 'Тяжёлая');

  const Severity(this.code, this.label);

  final String code;
  final String label;

  static Severity? fromCode(String? code) {
    if (code == null) return null;
    for (final s in Severity.values) {
      if (s.code == code) return s;
    }
    return null;
  }
}

/// Anthropometric metrics captured by a [LogType.measurement] entry.
/// All values are metric: centimetres and kilograms.
class Metrics {
  const Metrics({
    this.heightCm,
    this.weightKg,
    this.headCircumferenceCm,
    this.chestCircumferenceCm,
  });

  final double? heightCm;
  final double? weightKg;
  final double? headCircumferenceCm;
  final double? chestCircumferenceCm;

  bool get isEmpty =>
      heightCm == null &&
      weightKg == null &&
      headCircumferenceCm == null &&
      chestCircumferenceCm == null;

  Map<String, dynamic> toMap() => {
    if (heightCm != null) 'height_cm': heightCm,
    if (weightKg != null) 'weight_kg': weightKg,
    if (headCircumferenceCm != null) 'head_cm': headCircumferenceCm,
    if (chestCircumferenceCm != null) 'chest_cm': chestCircumferenceCm,
  };

  factory Metrics.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const Metrics();
    return Metrics(
      heightCm: parseDouble(map['height_cm']),
      weightKg: parseDouble(map['weight_kg']),
      headCircumferenceCm: parseDouble(map['head_cm']),
      chestCircumferenceCm: parseDouble(map['chest_cm']),
    );
  }
}

/// An entry in collection `development_logs`: diary note, milestone,
/// measurement or a day of illness.
class DevelopmentLog {
  const DevelopmentLog({
    required this.id,
    required this.childId,
    required this.date,
    required this.type,
    required this.title,
    this.description = '',
    this.metrics = const Metrics(),
    this.photos = const [],
    this.tags = const [],
    this.severity,
  });

  final String id;
  final String childId;
  final DateTime date;
  final LogType type;
  final String title;
  final String description;
  final Metrics metrics;
  final List<String> photos;
  final List<String> tags;
  final Severity? severity;

  DevelopmentLog copyWith({
    DateTime? date,
    LogType? type,
    String? title,
    String? description,
    Metrics? metrics,
    List<String>? photos,
    List<String>? tags,
    Severity? severity,
  }) {
    return DevelopmentLog(
      id: id,
      childId: childId,
      date: date ?? this.date,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      metrics: metrics ?? this.metrics,
      photos: photos ?? this.photos,
      tags: tags ?? this.tags,
      severity: severity ?? this.severity,
    );
  }

  Map<String, dynamic> toMap() => {
    'child_id': childId,
    'date': date.toIso8601String(),
    'type': type.code,
    'title': title,
    'description': description,
    'metrics': metrics.toMap(),
    'photos': photos,
    'tags': tags,
    if (severity != null) 'severity': severity!.code,
  };

  factory DevelopmentLog.fromMap(String id, Map<String, dynamic> map) {
    return DevelopmentLog(
      id: id,
      childId: map['child_id'] as String? ?? '',
      date: parseDate(map['date']) ?? DateTime.now(),
      type: LogType.fromCode(map['type'] as String?),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      metrics: Metrics.fromMap((map['metrics'] as Map?)?.cast<String, dynamic>()),
      photos: (map['photos'] as List?)?.cast<String>() ?? const [],
      tags: (map['tags'] as List?)?.cast<String>() ?? const [],
      severity: Severity.fromCode(map['severity'] as String?),
    );
  }
}
