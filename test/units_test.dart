import 'package:child_health_tracker/core/units/units.dart';
import 'package:child_health_tracker/models/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('conversion', () {
    test('matches the published definitions', () {
      // 1 lb is exactly 0.45359237 kg; 1 in is exactly 2.54 cm.
      expect(Units.kgToLb(1), closeTo(2.2046226, 0.0000001));
      expect(Units.lbToKg(1), closeTo(0.45359237, 0.0000001));
      expect(Units.cmToIn(2.54), closeTo(1, 1e-9));
      expect(Units.inToCm(1), closeTo(2.54, 1e-9));
    });

    test('round-trips without drift', () {
      for (final kg in [0.5, 3.3464, 9.6479, 18.3, 75.0]) {
        expect(Units.lbToKg(Units.kgToLb(kg)), closeTo(kg, 1e-9));
      }
      for (final cm in [30.0, 49.8842, 75.7, 110.0, 180.0]) {
        expect(Units.inToCm(Units.cmToIn(cm)), closeTo(cm, 1e-9));
      }
    });
  });

  group('metric is the storage format', () {
    test('metric values pass through untouched', () {
      // Nothing may be silently rescaled when the setting is metric.
      expect(Units.weightToStorage(9.6, UnitSystem.metric), 9.6);
      expect(Units.heightToStorage(75.7, UnitSystem.metric), 75.7);
      expect(Units.weightToDisplay(9.6, UnitSystem.metric), 9.6);
      expect(Units.heightToDisplay(75.7, UnitSystem.metric), 75.7);
    });

    test('what the parent types in imperial is stored in metric', () {
      // 21.16 lb entered must be filed as ~9.6 kg, because the WHO tables and
      // the doctor's report are both metric.
      final stored = Units.weightToStorage(21.164, UnitSystem.imperial);
      expect(stored, closeTo(9.6, 0.001));

      final storedHeight = Units.heightToStorage(29.803, UnitSystem.imperial);
      expect(storedHeight, closeTo(75.7, 0.01));
    });

    test('storing then displaying returns what was typed', () {
      // The round trip a parent actually experiences: type 21.2 lb, see 21.2.
      const typed = 21.2;
      final stored = Units.weightToStorage(typed, UnitSystem.imperial);
      final shown = Units.weightToDisplay(stored, UnitSystem.imperial);
      expect(shown, closeTo(typed, 1e-9));
    });

    test('switching the setting never alters stored data', () {
      // The whole safety argument in one assertion: the same stored value
      // simply reads differently, so flipping the toggle cannot corrupt a
      // child's history.
      const storedKg = 9.6479;
      final asMetric = Units.weightToDisplay(storedKg, UnitSystem.metric);
      final asImperial = Units.weightToDisplay(
        storedKg,
        UnitSystem.imperial,
      );
      expect(asMetric, storedKg);
      expect(asImperial, closeTo(21.269, 0.001));
      expect(Units.lbToKg(asImperial), closeTo(storedKg, 1e-9));
    });
  });

  group('labels', () {
    test('use the right unit per system', () {
      expect(Units.weightUnit(UnitSystem.metric), 'кг');
      expect(Units.weightUnit(UnitSystem.imperial), 'lb');
      expect(Units.heightUnit(UnitSystem.metric), 'см');
      expect(Units.heightUnit(UnitSystem.imperial), 'in');
    });

    test('format value and unit together', () {
      expect(Units.formatWeight(9.6479, UnitSystem.metric), '9.6 кг');
      expect(Units.formatHeight(75.7, UnitSystem.metric), '75.7 см');
      expect(Units.formatWeight(9.6479, UnitSystem.imperial), '21.3 lb');
      expect(Units.formatHeight(75.7, UnitSystem.imperial), '29.8 in');
    });

    test('temperature stays Celsius in both systems', () {
      // Deliberate: every threshold in the knowledge base and the triage
      // rules is stated in Celsius, and a converted reading beside an
      // unconverted rule is how a parent misreads a fever.
      expect(Units.formatTemperature(38.5), '38.5 °C');
    });
  });
}
