import 'json.dart';

enum LogType {
  milestone('milestone', 'Веха развития'),
  measurement('measurement', 'Измерение'),
  illness('illness', 'Болезнь'),
  feeding('feeding', 'Кормление'),
  nappy('nappy', 'Подгузник'),
  sleep('sleep', 'Сон'),
  question('question', 'Вопрос врачу'),
  note('note', 'Запись');

  const LogType(this.code, this.label);

  final String code;
  final String label;

  /// Entries a parent records many times a day, rather than occasionally.
  /// They get one-tap logging and daily counts instead of a form.
  bool get isRoutine =>
      this == LogType.feeding || this == LogType.nappy || this == LogType.sleep;

  /// Types the manual entry form offers. Routine care is logged by tapping a
  /// button on the dashboard, so putting it in a dropdown as well would only
  /// make the longer path look like the intended one.
  static List<LogType> get formTypes =>
      LogType.values.where((t) => !t.isRoutine).toList();

  static LogType fromCode(String? code) => LogType.values.firstWhere(
    (t) => t.code == code,
    orElse: () => LogType.note,
  );
}

/// Titles the quick actions write for entries that have no type of their own.
///
/// A dose given and a worry noted are both [LogType.note] documents — the
/// schema needs nothing added for them, and the title is what tells them
/// apart. Kept here, in Russian, because these strings are stored: they are
/// data written to Firestore, not interface, and translating them would orphan
/// every document already saved.
abstract final class LogTitles {
  static const medicine = 'Лекарство';
  static const alarm = 'Тревога';
  static const temperature = 'Температура';

  /// A photograph added for its own sake rather than attached to something
  /// that happened. It is still an ordinary entry on the timeline — a picture
  /// of a child on a Tuesday *is* what happened that Tuesday — so it carries
  /// the date and the words she wrote and nothing else.
  static const photo = 'Фото';
}

/// Which breast, or a bottle.
enum FeedingSide {
  left('left', 'Левая'),
  right('right', 'Правая'),
  bottle('bottle', 'Бутылочка');

  const FeedingSide(this.code, this.label);

  final String code;
  final String label;

  static FeedingSide? fromCode(String? code) {
    if (code == null) return null;
    for (final s in FeedingSide.values) {
      if (s.code == code) return s;
    }
    return null;
  }
}

/// What was in the nappy.
///
/// Wet nappies are counted separately because the knowledge base uses them as
/// the concrete test of whether a breastfed newborn is getting enough — six or
/// more in twenty-four hours. Counting them is the point of this entry type.
enum NappyKind {
  wet('wet', 'Мокрый'),
  dirty('dirty', 'Стул'),
  both('both', 'Мокрый и стул');

  const NappyKind(this.code, this.label);

  final String code;
  final String label;

  bool get countsAsWet => this == NappyKind.wet || this == NappyKind.both;

  bool get countsAsDirty => this == NappyKind.dirty || this == NappyKind.both;

  static NappyKind? fromCode(String? code) {
    if (code == null) return null;
    for (final k in NappyKind.values) {
      if (k.code == code) return k;
    }
    return null;
  }
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
    this.temperatureC,
  });

  final double? heightCm;
  final double? weightKg;
  final double? headCircumferenceCm;
  final double? chestCircumferenceCm;

  /// Body temperature in Celsius. Lives here rather than in a separate model
  /// because it is measured the same way as everything else — a number at a
  /// moment in time — and belongs on the same timeline.
  final double? temperatureC;

  bool get isEmpty =>
      heightCm == null &&
      weightKg == null &&
      headCircumferenceCm == null &&
      chestCircumferenceCm == null &&
      temperatureC == null;

  /// The WHO threshold for fever, used to colour the entry.
  bool get hasFever => (temperatureC ?? 0) >= 38.0;

  Map<String, dynamic> toMap() => {
    if (heightCm != null) 'height_cm': heightCm,
    if (weightKg != null) 'weight_kg': weightKg,
    if (headCircumferenceCm != null) 'head_cm': headCircumferenceCm,
    if (chestCircumferenceCm != null) 'chest_cm': chestCircumferenceCm,
    if (temperatureC != null) 'temperature_c': temperatureC,
  };

  factory Metrics.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const Metrics();
    return Metrics(
      heightCm: parseDouble(map['height_cm']),
      weightKg: parseDouble(map['weight_kg']),
      headCircumferenceCm: parseDouble(map['head_cm']),
      chestCircumferenceCm: parseDouble(map['chest_cm']),
      temperatureC: parseDouble(map['temperature_c']),
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
    this.feedingSide,
    this.nappyKind,
    this.durationMinutes,
    this.nightWakings,
    this.nightFeeds,
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

  /// Set on [LogType.feeding].
  final FeedingSide? feedingSide;

  /// Set on [LogType.nappy].
  final NappyKind? nappyKind;

  /// Minutes, for a feed or a stretch of sleep.
  final int? durationMinutes;

  /// How many times the child surfaced during a night, and how many of those
  /// ended in a feed.
  ///
  /// Present only on a night sleep, which is otherwise an ordinary
  /// [LogType.sleep] entry: the same duration, on the same timeline, counted
  /// by the same statistics. Nothing had to be added to the schema — a
  /// document written before this existed simply has neither field.
  final int? nightWakings;
  final int? nightFeeds;

  bool get isNightSleep => type == LogType.sleep && nightWakings != null;

  /// Local copy of the duration wording, so the model stays free of imports
  /// from the analytics layer.
  static String _duration(int minutes) {
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (hours == 0) return '$rest мин';
    if (rest == 0) return '$hours ч';
    return '$hours ч $rest мин';
  }

  /// One-line summary for the feed, e.g. "Левая · 15 мин".
  String get routineSummary => [
    if (feedingSide != null) feedingSide!.label,
    if (nappyKind != null) nappyKind!.label,
    if (durationMinutes != null) _duration(durationMinutes!),
    if ((nightWakings ?? 0) > 0)
      'пробуждений: $nightWakings',
    if ((nightFeeds ?? 0) > 0) 'кормлений: $nightFeeds',
  ].join(' · ');

  DevelopmentLog copyWith({
    DateTime? date,
    LogType? type,
    String? title,
    String? description,
    Metrics? metrics,
    List<String>? photos,
    List<String>? tags,
    Severity? severity,
    FeedingSide? feedingSide,
    NappyKind? nappyKind,
    int? durationMinutes,
    int? nightWakings,
    int? nightFeeds,
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
      feedingSide: feedingSide ?? this.feedingSide,
      nappyKind: nappyKind ?? this.nappyKind,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      nightWakings: nightWakings ?? this.nightWakings,
      nightFeeds: nightFeeds ?? this.nightFeeds,
    );
  }

  /// Same entry under a storage-assigned id. Drafts are created with an empty
  /// id and get a real one once the repository has written them.
  DevelopmentLog copyWithId(String newId) => DevelopmentLog(
    id: newId,
    childId: childId,
    date: date,
    type: type,
    title: title,
    description: description,
    metrics: metrics,
    photos: photos,
    tags: tags,
    severity: severity,
    feedingSide: feedingSide,
    nappyKind: nappyKind,
    durationMinutes: durationMinutes,
    nightWakings: nightWakings,
    nightFeeds: nightFeeds,
  );

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
    if (feedingSide != null) 'feeding_side': feedingSide!.code,
    if (nappyKind != null) 'nappy_kind': nappyKind!.code,
    if (durationMinutes != null) 'duration_minutes': durationMinutes,
    if (nightWakings != null) 'night_wakings': nightWakings,
    if (nightFeeds != null) 'night_feeds': nightFeeds,
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
      feedingSide: FeedingSide.fromCode(map['feeding_side'] as String?),
      nappyKind: NappyKind.fromCode(map['nappy_kind'] as String?),
      durationMinutes: (map['duration_minutes'] as num?)?.toInt(),
      nightWakings: (map['night_wakings'] as num?)?.toInt(),
      nightFeeds: (map['night_feeds'] as num?)?.toInt(),
    );
  }
}
