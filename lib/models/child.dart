import 'json.dart';

enum Gender {
  male('male', 'Мальчик'),
  female('female', 'Девочка');

  const Gender(this.code, this.label);

  final String code;
  final String label;

  static Gender fromCode(String? code) =>
      Gender.values.firstWhere((g) => g.code == code, orElse: () => Gender.male);
}

/// Profile of a child, collection `children` in the Firestore schema.
class Child {
  const Child({
    required this.id,
    required this.parentUid,
    required this.name,
    required this.birthDate,
    required this.gender,
    this.photoUrl,
  });

  final String id;
  final String parentUid;
  final String name;
  final DateTime birthDate;
  final Gender gender;
  final String? photoUrl;

  /// Whole months lived, the unit the WHO growth standards are indexed by.
  int ageInMonthsAt(DateTime moment) {
    var months =
        (moment.year - birthDate.year) * 12 + moment.month - birthDate.month;
    if (moment.day < birthDate.day) months--;
    return months < 0 ? 0 : months;
  }

  int get ageInMonths => ageInMonthsAt(DateTime.now());

  /// Human-readable age, e.g. "1 год 3 месяца" or "5 месяцев".
  ///
  /// Takes the reference moment explicitly so the formatting is testable
  /// without freezing the clock; [ageLabel] is the "as of now" shorthand.
  String ageLabelAt(DateTime moment) {
    final months = ageInMonthsAt(moment);
    final years = months ~/ 12;
    final rest = months % 12;
    if (years == 0) return _plural(rest, 'месяц', 'месяца', 'месяцев');
    if (rest == 0) return _plural(years, 'год', 'года', 'лет');
    return '${_plural(years, 'год', 'года', 'лет')} '
        '${_plural(rest, 'месяц', 'месяца', 'месяцев')}';
  }

  String get ageLabel => ageLabelAt(DateTime.now());

  Child copyWith({
    String? name,
    DateTime? birthDate,
    Gender? gender,
    String? photoUrl,
  }) {
    return Child(
      id: id,
      parentUid: parentUid,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  Map<String, dynamic> toMap() => {
    'parent_uid': parentUid,
    'name': name,
    'birth_date': birthDate.toIso8601String(),
    'gender': gender.code,
    'photo_url': photoUrl,
  };

  factory Child.fromMap(String id, Map<String, dynamic> map) {
    return Child(
      id: id,
      parentUid: map['parent_uid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      birthDate: parseDate(map['birth_date']) ?? DateTime.now(),
      gender: Gender.fromCode(map['gender'] as String?),
      photoUrl: map['photo_url'] as String?,
    );
  }
}

String _plural(int n, String one, String few, String many) {
  final mod100 = n % 100;
  final mod10 = n % 10;
  if (mod100 >= 11 && mod100 <= 14) return '$n $many';
  if (mod10 == 1) return '$n $one';
  if (mod10 >= 2 && mod10 <= 4) return '$n $few';
  return '$n $many';
}
