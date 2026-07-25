/// Helpers shared by the model layer.
///
/// Dates are stored as ISO-8601 strings so the in-memory repository and a
/// future Firestore one agree on the wire format. When Firestore is wired in,
/// [parseDate] is the single place that also has to accept a `Timestamp`.
DateTime? parseDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  // Firestore Timestamp exposes toDate(); reached only once cloud_firestore
  // is a dependency, so it is handled dynamically rather than by import.
  try {
    final dynamic dynamicValue = value;
    final converted = dynamicValue.toDate();
    if (converted is DateTime) return converted;
  } on NoSuchMethodError {
    return null;
  }
  return null;
}

/// Day-precision key used to group entries by calendar date.
DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

double? parseDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.replaceAll(',', '.'));
  return null;
}
