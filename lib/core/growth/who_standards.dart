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
/// ---------------------------------------------------------------------------
/// IMPORTANT: the table below is an ABRIDGED reference set covering 0-60 months
/// at selected ages, with intermediate ages linearly interpolated. It is good
/// enough to exercise the charts and the UI, but it is NOT the official WHO
/// dataset and must NOT be relied on for clinical decisions.
///
/// Before release, replace [_weightForAge] and [_heightForAge] with the full
/// month-by-month tables published at
/// https://www.who.int/tools/child-growth-standards/standards
/// (files wfa_boys_0-to-5-years_zscores.txt and friends).
/// ---------------------------------------------------------------------------
library;

import 'dart:math' as math;

import '../../models/child.dart';

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

/// Interpolated LMS coefficients for [metric] at [ageMonths].
/// Returns null when the age falls outside the covered range.
LmsPoint? lmsFor(GrowthMetric metric, Gender gender, int ageMonths) {
  final table = switch (metric) {
    GrowthMetric.weight =>
      gender == Gender.male ? _weightForAgeBoys : _weightForAgeGirls,
    GrowthMetric.height =>
      gender == Gender.male ? _heightForAgeBoys : _heightForAgeGirls,
  };
  if (table.isEmpty) return null;
  if (ageMonths <= table.first.month) return table.first;
  if (ageMonths >= table.last.month) return table.last;

  for (var i = 0; i < table.length - 1; i++) {
    final a = table[i];
    final b = table[i + 1];
    if (ageMonths >= a.month && ageMonths <= b.month) {
      final span = b.month - a.month;
      if (span == 0) return a;
      final t = (ageMonths - a.month) / span;
      return LmsPoint(
        ageMonths,
        a.l + (b.l - a.l) * t,
        a.m + (b.m - a.m) * t,
        a.s + (b.s - a.s) * t,
      );
    }
  }
  return null;
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

// --- Abridged reference tables -------------------------------------------
// Ages: 0, 1, 2, 3, 6, 9, 12, 18, 24, 36, 48, 60 months.

const _weightForAgeBoys = <LmsPoint>[
  LmsPoint(0, 0.3487, 3.3464, 0.14602),
  LmsPoint(1, 0.2297, 4.4709, 0.13395),
  LmsPoint(2, 0.1970, 5.5675, 0.12385),
  LmsPoint(3, 0.1738, 6.3762, 0.11727),
  LmsPoint(6, 0.1257, 7.9340, 0.10958),
  LmsPoint(9, 0.0917, 8.9014, 0.10902),
  LmsPoint(12, 0.0653, 9.6479, 0.11015),
  LmsPoint(18, 0.0217, 10.9385, 0.11316),
  LmsPoint(24, -0.0137, 12.1515, 0.11660),
  LmsPoint(36, -0.0730, 14.3429, 0.12328),
  LmsPoint(48, -0.1207, 16.3489, 0.13035),
  LmsPoint(60, -0.1600, 18.3457, 0.13775),
];

const _weightForAgeGirls = <LmsPoint>[
  LmsPoint(0, 0.3809, 3.2322, 0.14171),
  LmsPoint(1, 0.1714, 4.1873, 0.13724),
  LmsPoint(2, 0.0962, 5.1282, 0.13000),
  LmsPoint(3, 0.0402, 5.8458, 0.12619),
  LmsPoint(6, -0.0756, 7.2970, 0.12204),
  LmsPoint(9, -0.1387, 8.2254, 0.12252),
  LmsPoint(12, -0.1770, 8.9481, 0.12386),
  LmsPoint(18, -0.2245, 10.2315, 0.12690),
  LmsPoint(24, -0.2543, 11.4775, 0.13011),
  LmsPoint(36, -0.2860, 13.8619, 0.13674),
  LmsPoint(48, -0.3024, 16.0700, 0.14413),
  LmsPoint(60, -0.3110, 18.2193, 0.15181),
];

const _heightForAgeBoys = <LmsPoint>[
  LmsPoint(0, 1.0, 49.8842, 0.03795),
  LmsPoint(1, 1.0, 54.7244, 0.03557),
  LmsPoint(2, 1.0, 58.4249, 0.03424),
  LmsPoint(3, 1.0, 61.4292, 0.03328),
  LmsPoint(6, 1.0, 67.6236, 0.03257),
  LmsPoint(9, 1.0, 72.0000, 0.03317),
  LmsPoint(12, 1.0, 75.7488, 0.03400),
  LmsPoint(18, 1.0, 82.2587, 0.03549),
  LmsPoint(24, 1.0, 87.1161, 0.03694),
  LmsPoint(36, 1.0, 96.0835, 0.03907),
  LmsPoint(48, 1.0, 103.3273, 0.04055),
  LmsPoint(60, 1.0, 110.0000, 0.04193),
];

const _heightForAgeGirls = <LmsPoint>[
  LmsPoint(0, 1.0, 49.1477, 0.03790),
  LmsPoint(1, 1.0, 53.6872, 0.03640),
  LmsPoint(2, 1.0, 57.0673, 0.03568),
  LmsPoint(3, 1.0, 59.8029, 0.03518),
  LmsPoint(6, 1.0, 65.7311, 0.03502),
  LmsPoint(9, 1.0, 70.1435, 0.03583),
  LmsPoint(12, 1.0, 74.0150, 0.03687),
  LmsPoint(18, 1.0, 80.7079, 0.03865),
  LmsPoint(24, 1.0, 85.7153, 0.04007),
  LmsPoint(36, 1.0, 95.0951, 0.04236),
  LmsPoint(48, 1.0, 102.7312, 0.04395),
  LmsPoint(60, 1.0, 109.4233, 0.04520),
];
