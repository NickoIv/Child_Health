import 'package:child_health_tracker/knowledge/triage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the age-and-fever rule', () {
    test('any fever under 3 months is an emergency', () {
      // NICE NG143: infants this young mount almost no other signs of serious
      // bacterial infection, so the temperature alone decides.
      for (final age in [0, 1, 2]) {
        final r = runTriage(
          ageMonths: age,
          answeredYes: const {},
          temperature: 38.0,
        );
        expect(
          r.level,
          TriageLevel.emergency,
          reason: 'age $age months with 38.0 must escalate',
        );
        expect(r.temperatureRule, isNotNull);
      }
    });

    test('the under-3-months rule does not fire below 38', () {
      final r = runTriage(
        ageMonths: 1,
        answeredYes: const {},
        temperature: 37.9,
      );
      expect(r.level, TriageLevel.home);
    });

    test('the rule stops applying at 3 months', () {
      final r = runTriage(
        ageMonths: 3,
        answeredYes: const {},
        temperature: 38.0,
      );
      expect(r.level, isNot(TriageLevel.emergency));
    });

    test('39 and above under 6 months needs a doctor today', () {
      final r = runTriage(
        ageMonths: 4,
        answeredYes: const {},
        temperature: 39.2,
      );
      expect(r.level, TriageLevel.today);
      expect(r.temperatureRule, contains('39.2'));
    });

    test('40 and above needs a doctor today at any age', () {
      final r = runTriage(
        ageMonths: 60,
        answeredYes: const {},
        temperature: 40.1,
      );
      expect(r.level, TriageLevel.today);
    });

    test('an ordinary fever in an older child is not escalated by itself', () {
      final r = runTriage(
        ageMonths: 24,
        answeredYes: const {},
        temperature: 38.6,
      );
      expect(r.level, TriageLevel.home);
      expect(r.temperatureRule, isNull);
    });

    test('no temperature given is handled', () {
      final r = runTriage(ageMonths: 1, answeredYes: const {});
      expect(r.level, TriageLevel.home);
      expect(r.temperatureRule, isNull);
    });
  });

  group('red flags', () {
    test('each emergency question on its own triggers an emergency', () {
      final emergencyIds = triageQuestions
          .where((q) => q.levelIfYes == TriageLevel.emergency)
          .map((q) => q.id);
      expect(emergencyIds, isNotEmpty);

      for (final id in emergencyIds) {
        final r = runTriage(ageMonths: 12, answeredYes: {id});
        expect(
          r.level,
          TriageLevel.emergency,
          reason: 'question "$id" must escalate on its own',
        );
      }
    });

    test('nothing checked means home care', () {
      final r = runTriage(ageMonths: 12, answeredYes: const {});
      expect(r.level, TriageLevel.home);
      expect(r.reasons, isEmpty);
    });

    test('the most severe answer wins', () {
      final r = runTriage(
        ageMonths: 12,
        answeredYes: const {'parent-worried', 'breathing', 'ear-pain'},
      );
      expect(r.level, TriageLevel.emergency);
    });

    test('reasons are ordered most severe first', () {
      final r = runTriage(
        ageMonths: 12,
        answeredYes: const {'ear-pain', 'breathing', 'not-drinking'},
      );
      expect(r.reasons.first.id, 'breathing');
      expect(r.reasons.last.id, 'ear-pain');
    });

    test('a worried parent alone is never dismissed', () {
      final r = runTriage(
        ageMonths: 12,
        answeredYes: const {'parent-worried'},
      );
      expect(r.level, TriageLevel.soon);
      expect(r.level, isNot(TriageLevel.home));
    });

    test('unknown answer ids are ignored rather than crashing', () {
      final r = runTriage(
        ageMonths: 12,
        answeredYes: const {'not-a-real-question'},
      );
      expect(r.level, TriageLevel.home);
    });
  });

  group('age-scoped questions', () {
    test('the nappy question is not asked about a schoolchild', () {
      final ids = questionsForAge(120).map((q) => q.id);
      expect(ids, isNot(contains('fewer-nappies')));
    });

    test('it is asked about an infant', () {
      final ids = questionsForAge(6).map((q) => q.id);
      expect(ids, contains('fewer-nappies'));
    });

    test('an out-of-range answer cannot raise the level', () {
      // Checking a question that does not apply at this age must not count.
      final r = runTriage(
        ageMonths: 120,
        answeredYes: const {'fewer-nappies'},
      );
      expect(r.level, TriageLevel.home);
      expect(r.reasons, isEmpty);
    });
  });

  group('level ordering', () {
    test('severity compares correctly', () {
      expect(TriageLevel.emergency > TriageLevel.today, isTrue);
      expect(TriageLevel.today > TriageLevel.soon, isTrue);
      expect(TriageLevel.soon > TriageLevel.home, isTrue);
      expect(TriageLevel.home > TriageLevel.emergency, isFalse);
    });

    test('every level ends by pointing at a doctor or ambulance', () {
      for (final level in TriageLevel.values) {
        final text = '${level.title} ${level.advice}'.toLowerCase();
        expect(
          text.contains('врач') ||
              text.contains('скорую') ||
              text.contains('103') ||
              text.contains('педиатр'),
          isTrue,
          reason: '«${level.title}» must route the parent to a clinician',
        );
      }
    });
  });

  group('determinism', () {
    test('identical input gives identical output', () {
      TriageResult run() => runTriage(
        ageMonths: 2,
        answeredYes: const {'not-drinking', 'ear-pain'},
        temperature: 38.4,
      );
      final a = run();
      final b = run();
      expect(a.level, b.level);
      expect(a.temperatureRule, b.temperatureRule);
      expect(
        a.reasons.map((r) => r.id).toList(),
        b.reasons.map((r) => r.id).toList(),
      );
    });
  });
}
