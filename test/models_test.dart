import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/models/medical_record.dart';
import 'package:child_health_tracker/models/reminder.dart';
import 'package:flutter_test/flutter_test.dart';

Child _child({DateTime? birth, Gender gender = Gender.male}) => Child(
  id: 'c1',
  parentUid: 'p1',
  name: 'Тест',
  birthDate: birth ?? DateTime(2025, 1, 15),
  gender: gender,
);

void main() {
  group('Child.ageInMonthsAt', () {
    test('counts whole months only', () {
      final child = _child(birth: DateTime(2025, 1, 15));
      expect(child.ageInMonthsAt(DateTime(2025, 1, 15)), 0);
      expect(child.ageInMonthsAt(DateTime(2025, 2, 14)), 0);
      expect(child.ageInMonthsAt(DateTime(2025, 2, 15)), 1);
      expect(child.ageInMonthsAt(DateTime(2026, 1, 15)), 12);
      expect(child.ageInMonthsAt(DateTime(2026, 1, 14)), 11);
    });

    test('never goes negative for a date before birth', () {
      final child = _child(birth: DateTime(2025, 6, 1));
      expect(child.ageInMonthsAt(DateTime(2025, 1, 1)), 0);
    });
  });

  group('Child.ageLabelAt', () {
    // Fixed reference date so the assertions do not drift with the clock.
    final now = DateTime(2026, 7, 25);

    String label(int monthsAgo) {
      final birth = DateTime(now.year, now.month - monthsAgo, now.day);
      return _child(birth: birth).ageLabelAt(now);
    }

    test('agrees Russian nouns with the number', () {
      expect(label(1), '1 месяц');
      expect(label(3), '3 месяца');
      expect(label(5), '5 месяцев');
      expect(label(11), '11 месяцев');
      expect(label(12), '1 год');
      expect(label(24), '2 года');
      expect(label(60), '5 лет');
    });

    test('combines years and months', () {
      expect(label(15), '1 год 3 месяца');
      expect(label(26), '2 года 2 месяца');
    });

    test('handles the 11-14 exception to the plural rule', () {
      expect(_child(birth: DateTime(now.year - 11, now.month, now.day))
          .ageLabelAt(now), '11 лет');
      expect(_child(birth: DateTime(now.year - 14, now.month, now.day))
          .ageLabelAt(now), '14 лет');
    });
  });

  group('serialisation round-trips', () {
    test('Child survives toMap/fromMap', () {
      final original = _child(gender: Gender.female);
      final restored = Child.fromMap(original.id, original.toMap());
      expect(restored.name, original.name);
      expect(restored.parentUid, original.parentUid);
      expect(restored.gender, Gender.female);
      expect(restored.birthDate, original.birthDate);
    });

    test('DevelopmentLog keeps metrics, tags and severity', () {
      final original = DevelopmentLog(
        id: 'l1',
        childId: 'c1',
        date: DateTime(2026, 3, 4),
        type: LogType.illness,
        title: 'ОРВИ',
        description: 'Температура',
        metrics: const Metrics(weightKg: 9.4, heightCm: 74.1),
        tags: const ['ОРВИ', 'зима'],
        severity: Severity.moderate,
      );
      final restored = DevelopmentLog.fromMap('l1', original.toMap());
      expect(restored.type, LogType.illness);
      expect(restored.severity, Severity.moderate);
      expect(restored.tags, ['ОРВИ', 'зима']);
      expect(restored.metrics.weightKg, 9.4);
      expect(restored.metrics.heightCm, 74.1);
    });

    test('Reminder survives toMap/fromMap', () {
      final original = Reminder(
        id: 'r1',
        childId: 'c1',
        type: ReminderType.medication,
        title: 'Витамин D',
        scheduledTime: DateTime(2026, 7, 25, 9),
        recurrence: Recurrence.daily,
        details: '500 МЕ',
      );
      final restored = Reminder.fromMap('r1', original.toMap());
      expect(restored.type, ReminderType.medication);
      expect(restored.recurrence, Recurrence.daily);
      expect(restored.scheduledTime, original.scheduledTime);
      expect(restored.isCompleted, isFalse);
    });

    test('unknown enum codes fall back instead of throwing', () {
      final log = DevelopmentLog.fromMap('x', {'type': 'nonsense'});
      expect(log.type, LogType.note);
      final child = Child.fromMap('x', {'gender': 'nonsense'});
      expect(child.gender, Gender.male);
    });
  });

  group('LabResult reference ranges', () {
    test('flags values outside the interval', () {
      const low = LabResult(
        name: 'Гемоглобин',
        value: 95,
        unit: 'г/л',
        referenceMin: 110,
        referenceMax: 140,
      );
      const ok = LabResult(
        name: 'Гемоглобин',
        value: 120,
        unit: 'г/л',
        referenceMin: 110,
        referenceMax: 140,
      );
      const high = LabResult(
        name: 'Лейкоциты',
        value: 20,
        unit: '10⁹/л',
        referenceMin: 6,
        referenceMax: 12,
      );
      expect(low.isWithinReference, isFalse);
      expect(ok.isWithinReference, isTrue);
      expect(high.isWithinReference, isFalse);
    });

    test('returns null when there is nothing to compare against', () {
      const r = LabResult(name: 'Цвет', value: 1, unit: '');
      expect(r.isWithinReference, isNull);
      expect(r.referenceLabel, '—');
    });

    test('counts out-of-range results in a record', () {
      final record = MedicalRecord(
        id: 'm1',
        childId: 'c1',
        date: DateTime(2026, 5, 1),
        diagnosis: 'ОРВИ',
        labResults: const [
          LabResult(
            name: 'A',
            value: 5,
            unit: '',
            referenceMin: 1,
            referenceMax: 10,
          ),
          LabResult(
            name: 'B',
            value: 50,
            unit: '',
            referenceMin: 1,
            referenceMax: 10,
          ),
        ],
      );
      expect(record.outOfRangeCount, 1);
    });
  });
}

