import 'json.dart';

/// A single laboratory measurement inside a [MedicalRecord].
class LabResult {
  const LabResult({
    required this.name,
    required this.value,
    required this.unit,
    this.referenceMin,
    this.referenceMax,
  });

  final String name;
  final double value;
  final String unit;
  final double? referenceMin;
  final double? referenceMax;

  /// Null when the analysis carries no reference interval, so the UI can tell
  /// "within range" apart from "nothing to compare against".
  bool? get isWithinReference {
    if (referenceMin == null && referenceMax == null) return null;
    if (referenceMin != null && value < referenceMin!) return false;
    if (referenceMax != null && value > referenceMax!) return false;
    return true;
  }

  String get referenceLabel {
    if (referenceMin != null && referenceMax != null) {
      return '$referenceMin – $referenceMax $unit';
    }
    if (referenceMin != null) return 'от $referenceMin $unit';
    if (referenceMax != null) return 'до $referenceMax $unit';
    return '—';
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'value': value,
    'unit': unit,
    'reference_min': referenceMin,
    'reference_max': referenceMax,
  };

  factory LabResult.fromMap(Map<String, dynamic> map) => LabResult(
    name: map['name'] as String? ?? '',
    value: parseDouble(map['value']) ?? 0,
    unit: map['unit'] as String? ?? '',
    referenceMin: parseDouble(map['reference_min']),
    referenceMax: parseDouble(map['reference_max']),
  );
}

/// An entry in collection `medical_records`: a visit outcome with diagnoses,
/// prescriptions, lab results and scans of paper forms.
class MedicalRecord {
  const MedicalRecord({
    required this.id,
    required this.childId,
    required this.date,
    required this.diagnosis,
    this.prescriptions = '',
    this.labResults = const [],
    this.files = const [],
    this.doctor = '',
  });

  final String id;
  final String childId;
  final DateTime date;
  final String diagnosis;
  final String prescriptions;
  final List<LabResult> labResults;

  /// Storage URLs of uploaded scans (PDF, JPG, PNG).
  final List<String> files;
  final String doctor;

  int get outOfRangeCount =>
      labResults.where((r) => r.isWithinReference == false).length;

  MedicalRecord copyWith({
    DateTime? date,
    String? diagnosis,
    String? prescriptions,
    List<LabResult>? labResults,
    List<String>? files,
    String? doctor,
  }) {
    return MedicalRecord(
      id: id,
      childId: childId,
      date: date ?? this.date,
      diagnosis: diagnosis ?? this.diagnosis,
      prescriptions: prescriptions ?? this.prescriptions,
      labResults: labResults ?? this.labResults,
      files: files ?? this.files,
      doctor: doctor ?? this.doctor,
    );
  }

  /// Same record under a storage-assigned id.
  MedicalRecord copyWithId(String newId) => MedicalRecord(
    id: newId,
    childId: childId,
    date: date,
    diagnosis: diagnosis,
    prescriptions: prescriptions,
    labResults: labResults,
    files: files,
    doctor: doctor,
  );

  Map<String, dynamic> toMap() => {
    'child_id': childId,
    'date': date.toIso8601String(),
    'diagnosis': diagnosis,
    'prescriptions': prescriptions,
    'lab_results': labResults.map((r) => r.toMap()).toList(),
    'files': files,
    'doctor': doctor,
  };

  factory MedicalRecord.fromMap(String id, Map<String, dynamic> map) {
    return MedicalRecord(
      id: id,
      childId: map['child_id'] as String? ?? '',
      date: parseDate(map['date']) ?? DateTime.now(),
      diagnosis: map['diagnosis'] as String? ?? '',
      prescriptions: map['prescriptions'] as String? ?? '',
      labResults: (map['lab_results'] as List? ?? const [])
          .map((e) => LabResult.fromMap((e as Map).cast<String, dynamic>()))
          .toList(),
      files: (map['files'] as List?)?.cast<String>() ?? const [],
      doctor: map['doctor'] as String? ?? '',
    );
  }
}
