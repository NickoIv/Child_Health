/// WHO Child Growth Standards, expressed as LMS coefficients.
///
/// The WHO publishes, for every age in months, a Box-Cox power (L), a median
/// (M) and a coefficient of variation (S). A measurement is converted to a
/// z-score with
///
///   z = ((value / M)^L - 1) / (L * S)      for L != 0
///   z = ln(value / M) / S                  for L == 0
///
/// and the z-score is then mapped to a percentile through the standard normal
/// CDF.
///
/// The tables live in `who_tables.dart` and are GENERATED from the published
/// dataset by `tool/generate_who_tables.py` — complete monthly coverage,
/// 0-60 months, both sexes. They are not hand-written, and must not become so:
/// an earlier hand-transcribed version had correct medians but L and S
/// coefficients that were off by enough to shift every z-score.
///
/// Still not a diagnostic instrument. A z-score is a position on a population
/// curve, not a clinical conclusion.
library;

import 'dart:math' as math;

import '../../models/child.dart';

part 'who_tables.dart';

/// Highest age the reference tables cover, in months.
const referenceMaxMonth = 60;

/// One row of the WHO reference: age in months plus the L, M, S coefficients.
class LmsPoint {
  const LmsPoint(this.month, this.l, this.m, this.s);

  final int month;
  final double l;
  final double m;
  final double s;
}

enum GrowthMetric {
  weight('Вес', 'кг'),
  height('Рост', 'см');

  const GrowthMetric(this.label, this.unit);

  final String label;
  final String unit;
}

/// Published LMS coefficients for [metric] at [ageMonths].
///
/// The tables now cover every month from 0 to 60, so this is a direct lookup:
/// no interpolation, and therefore no interpolation error. Ages are whole
/// months by construction — [Child.ageInMonthsAt] floors them.
///
/// Returns null past the end of the range. Clamping to the last row instead
/// would silently score a ten-year-old against the norms for a five-year-old
/// and present the result as a real verdict.
LmsPoint? lmsFor(GrowthMetric metric, Gender gender, int ageMonths) {
  final table = switch (metric) {
    GrowthMetric.weight =>
      gender == Gender.male ? _weightForAgeBoys : _weightForAgeGirls,
    GrowthMetric.height =>
      gender == Gender.male ? _heightForAgeBoys : _heightForAgeGirls,
  };
  if (table.isEmpty) return null;
  if (ageMonths < 0) return table.first;
  if (ageMonths >= table.length) return null;
  return table[ageMonths];
}

/// Z-score of [value] against the WHO reference, or null if out of range.
double? zScore(
  GrowthMetric metric,
  Gender gender,
  int ageMonths,
  double value,
) {
  final lms = lmsFor(metric, gender, ageMonths);
  if (lms == null || value <= 0) return null;
  if (lms.l.abs() < 1e-7) {
    return math.log(value / lms.m) / lms.s;
  }
  return (math.pow(value / lms.m, lms.l) - 1) / (lms.l * lms.s);
}

/// Percentile (0-100) matching [z], via an Abramowitz & Stegun approximation
/// of the standard normal CDF (absolute error below 7.5e-8).
double percentileFromZ(double z) {
  final sign = z < 0 ? -1.0 : 1.0;
  final x = z.abs() / math.sqrt2;
  const a1 = 0.254829592;
  const a2 = -0.284496736;
  const a3 = 1.421413741;
  const a4 = -1.453152027;
  const a5 = 1.061405429;
  const p = 0.3275911;
  final t = 1.0 / (1.0 + p * x);
  final y =
      1.0 -
      (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-x * x);
  return 50.0 * (1.0 + sign * y);
}

/// Median value of [metric] at [ageMonths] — the 50th percentile curve.
double? medianFor(GrowthMetric metric, Gender gender, int ageMonths) =>
    lmsFor(metric, gender, ageMonths)?.m;

/// Value at an arbitrary z on the reference curve, used to draw the
/// -2SD / +2SD band around the median.
double? valueAtZ(
  GrowthMetric metric,
  Gender gender,
  int ageMonths,
  double z,
) {
  final lms = lmsFor(metric, gender, ageMonths);
  if (lms == null) return null;
  if (lms.l.abs() < 1e-7) {
    return lms.m * math.exp(lms.s * z);
  }
  return lms.m * math.pow(1 + lms.l * lms.s * z, 1 / lms.l);
}

/// Clinical reading of a z-score, following the WHO cut-offs at ±2 and ±3 SD.
enum GrowthVerdict {
  severelyLow('Значительно ниже нормы'),
  low('Ниже нормы'),
  normal('В пределах нормы'),
  high('Выше нормы'),
  severelyHigh('Значительно выше нормы');

  const GrowthVerdict(this.label);

  final String label;
}

GrowthVerdict verdictFromZ(double z) {
  if (z < -3) return GrowthVerdict.severelyLow;
  if (z < -2) return GrowthVerdict.low;
  if (z > 3) return GrowthVerdict.severelyHigh;
  if (z > 2) return GrowthVerdict.high;
  return GrowthVerdict.normal;
}
