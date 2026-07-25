import 'package:child_health_tracker/core/growth/who_standards.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LMS lookup', () {
    test('returns the tabulated point at an exact age', () {
      final point = lmsFor(GrowthMetric.weight, Gender.male, 12);
      expect(point, isNotNull);
      expect(point!.m, closeTo(9.6479, 1e-4));
    });

    test('interpolates between tabulated ages', () {
      final at12 = lmsFor(GrowthMetric.weight, Gender.male, 12)!.m;
      final at18 = lmsFor(GrowthMetric.weight, Gender.male, 18)!.m;
      final at15 = lmsFor(GrowthMetric.weight, Gender.male, 15)!.m;
      expect(at15, greaterThan(at12));
      expect(at15, lessThan(at18));
      expect(at15, closeTo((at12 + at18) / 2, 1e-6));
    });

    test('clamps below and above the covered range', () {
      expect(lmsFor(GrowthMetric.weight, Gender.male, -5)!.month, 0);
      expect(lmsFor(GrowthMetric.weight, Gender.male, 200)!.month, 60);
    });
  });

  group('z-score', () {
    test('a child exactly on the median scores zero', () {
      for (final gender in Gender.values) {
        for (final month in [0, 6, 12, 24, 60]) {
          final median = medianFor(GrowthMetric.weight, gender, month)!;
          final z = zScore(GrowthMetric.weight, gender, month, median)!;
          expect(z, closeTo(0, 1e-9), reason: '$gender at $month months');
        }
      }
    });

    test('is monotonic in the measured value', () {
      final light = zScore(GrowthMetric.weight, Gender.female, 12, 7.5)!;
      final heavy = zScore(GrowthMetric.weight, Gender.female, 12, 11.0)!;
      expect(light, lessThan(heavy));
    });

    test('rejects non-positive measurements', () {
      expect(zScore(GrowthMetric.weight, Gender.male, 12, 0), isNull);
      expect(zScore(GrowthMetric.weight, Gender.male, 12, -3), isNull);
    });
  });

  group('percentile', () {
    test('z = 0 maps to the 50th percentile', () {
      expect(percentileFromZ(0), closeTo(50, 1e-6));
    });

    test('matches the known values of the normal distribution', () {
      // ±1 SD covers ~68.27%, so the tails sit at 15.87 and 84.13.
      expect(percentileFromZ(-1), closeTo(15.87, 0.01));
      expect(percentileFromZ(1), closeTo(84.13, 0.01));
      expect(percentileFromZ(-2), closeTo(2.28, 0.01));
      expect(percentileFromZ(2), closeTo(97.72, 0.01));
    });

    test('stays inside 0..100', () {
      for (final z in [-6.0, -3.0, 0.0, 3.0, 6.0]) {
        final p = percentileFromZ(z);
        expect(p, inInclusiveRange(0, 100));
      }
    });
  });

  group('valueAtZ', () {
    test('round-trips with zScore', () {
      final value = valueAtZ(GrowthMetric.weight, Gender.male, 24, 1.5)!;
      final z = zScore(GrowthMetric.weight, Gender.male, 24, value)!;
      expect(z, closeTo(1.5, 1e-6));
    });

    test('the -2SD curve lies below the median, +2SD above', () {
      final low = valueAtZ(GrowthMetric.height, Gender.female, 12, -2)!;
      final median = medianFor(GrowthMetric.height, Gender.female, 12)!;
      final high = valueAtZ(GrowthMetric.height, Gender.female, 12, 2)!;
      expect(low, lessThan(median));
      expect(high, greaterThan(median));
    });
  });

  group('verdict', () {
    test('applies the WHO cut-offs at +/-2 and +/-3 SD', () {
      expect(verdictFromZ(0), GrowthVerdict.normal);
      expect(verdictFromZ(1.9), GrowthVerdict.normal);
      expect(verdictFromZ(-2.5), GrowthVerdict.low);
      expect(verdictFromZ(2.5), GrowthVerdict.high);
      expect(verdictFromZ(-3.5), GrowthVerdict.severelyLow);
      expect(verdictFromZ(3.5), GrowthVerdict.severelyHigh);
    });
  });
}
