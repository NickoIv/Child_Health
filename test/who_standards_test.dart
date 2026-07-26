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

    test('covers every month with its own published row', () {
      // The tables are complete, so nothing is interpolated any more. An
      // earlier version guessed month 15 as the midpoint of 12 and 18; the
      // published value is not the midpoint, and that error propagated into
      // every z-score computed at an unlisted age.
      for (final metric in GrowthMetric.values) {
        for (final gender in Gender.values) {
          for (var month = 0; month <= referenceMaxMonth; month++) {
            final point = lmsFor(metric, gender, month);
            expect(
              point,
              isNotNull,
              reason: '$metric $gender has no row for month $month',
            );
            expect(point!.month, month);
          }
        }
      }
    });

    test('the median rises month over month', () {
      for (final metric in GrowthMetric.values) {
        for (final gender in Gender.values) {
          for (var month = 1; month <= referenceMaxMonth; month++) {
            final previous = lmsFor(metric, gender, month - 1)!.m;
            final current = lmsFor(metric, gender, month)!.m;
            expect(
              current,
              greaterThan(previous),
              reason: '$metric $gender fell between $month and ${month - 1}',
            );
          }
        }
      }
    });

    test('matches values published by the WHO', () {
      // Guards against a bad regeneration: these are spot values from the
      // official standards.
      expect(
        lmsFor(GrowthMetric.weight, Gender.male, 12)!.m,
        closeTo(9.6479, 0.0001),
      );
      expect(
        lmsFor(GrowthMetric.weight, Gender.male, 0)!.m,
        closeTo(3.3464, 0.0001),
      );
      expect(
        lmsFor(GrowthMetric.weight, Gender.female, 0)!.m,
        closeTo(3.2322, 0.0001),
      );
      expect(
        lmsFor(GrowthMetric.height, Gender.male, 0)!.m,
        closeTo(49.8842, 0.0001),
      );
      expect(
        lmsFor(GrowthMetric.height, Gender.female, 0)!.m,
        closeTo(49.1477, 0.0001),
      );
    });

    test('L and S are plausible everywhere', () {
      for (final metric in GrowthMetric.values) {
        for (final gender in Gender.values) {
          for (var month = 0; month <= referenceMaxMonth; month++) {
            final p = lmsFor(metric, gender, month)!;
            expect(p.m, greaterThan(0));
            expect(p.s, greaterThan(0));
            expect(p.s, lessThan(0.5));
            expect(p.l.abs(), lessThan(3));
          }
        }
      }
    });

    test('clamps below the covered range', () {
      expect(lmsFor(GrowthMetric.weight, Gender.male, -5)!.month, 0);
      expect(lmsFor(GrowthMetric.weight, Gender.male, 0)!.month, 0);
    });

    test('returns the last row exactly at the end of the range', () {
      expect(
        lmsFor(GrowthMetric.weight, Gender.male, referenceMaxMonth)!.month,
        referenceMaxMonth,
      );
    });

    test('refuses to extrapolate past the end of the tables', () {
      // Returning the 60-month row here would score a school-age child
      // against toddler norms and present it as a real verdict.
      expect(lmsFor(GrowthMetric.weight, Gender.male, 61), isNull);
      expect(lmsFor(GrowthMetric.height, Gender.female, 200), isNull);
      expect(zScore(GrowthMetric.weight, Gender.male, 120, 30), isNull);
      expect(medianFor(GrowthMetric.height, Gender.male, 120), isNull);
      expect(valueAtZ(GrowthMetric.weight, Gender.female, 120, 0), isNull);
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
