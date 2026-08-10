import 'package:child_health_tracker/knowledge/milestones.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:flutter_test/flutter_test.dart';

/// The developmental table, and the promises it makes.
///
/// This is the feature every parenting app has and most of them get wrong the
/// same way: a date, a checkbox and the word «должен». What follows is not
/// really testing arithmetic — it is holding the table to the four rules that
/// make it support rather than an exam.
void main() {
  DevelopmentLog milestone(String title, {String description = ''}) =>
      DevelopmentLog(
        id: title,
        childId: 'c1',
        date: DateTime(2026, 6, 1),
        type: LogType.milestone,
        title: title,
        description: description,
      );

  group('the windows', () {
    test('are windows and not dates', () {
      // The narrowest thing in the table still spans months. A one-month
      // window is a deadline with extra steps.
      for (final m in milestones) {
        expect(
          m.toMonths - m.fromMonths,
          greaterThanOrEqualTo(2),
          reason: '${m.id} is too narrow to be honest',
        );
        expect(m.fromMonths, lessThan(m.toMonths), reason: m.id);
      }
    });

    test('follow the WHO where the WHO has measured it', () {
      // Sitting without support and walking alone are the two every parent
      // counts the weeks to, and the WHO's own windows run 1st to 99th
      // percentile. Narrowing them would be inventing certainty.
      final sit = milestones.firstWhere((m) => m.id == 'sit');
      expect(sit.fromMonths, lessThanOrEqualTo(4));
      expect(sit.toMonths, greaterThanOrEqualTo(9));

      final walk = milestones.firstWhere((m) => m.id == 'walk');
      expect(walk.fromMonths, lessThanOrEqualTo(8));
      expect(walk.toMonths, greaterThanOrEqualTo(17));
    });

    test('carry no duplicate ids', () {
      final ids = milestones.map((m) => m.id).toSet();
      expect(ids.length, milestones.length);
    });
  });

  group('what is shown at an age', () {
    test('includes both ends of the window', () {
      final roll = milestones.firstWhere((m) => m.id == 'roll');
      expect(milestonesUsualAt(roll.fromMonths), contains(roll));
      expect(milestonesUsualAt(roll.toMonths), contains(roll));
    });

    test('drops a window that has closed instead of flagging it', () {
      // The whole point. A one-year-old who never had «улыбается в ответь»
      // written down is not told about it — there is no list of what a child
      // has failed to do, and there is no function here that could build one.
      final usual = milestonesUsualAt(12).map((m) => m.id);
      expect(usual, isNot(contains('smile')));
      expect(usual, isNot(contains('coo')));
    });

    test('has something to say at every month up to three years', () {
      // Otherwise the card is blank for a child of exactly eleven months and
      // the app looks like it stopped caring at ten.
      for (var age = 0; age <= 36; age++) {
        final anything =
            milestonesUsualAt(age).isNotEmpty ||
            milestonesSoonAfter(age).isNotEmpty;
        expect(anything, isTrue, reason: 'nothing to show at $age months');
      }
    });

    test('what is coming is ahead, never behind', () {
      for (final m in milestonesSoonAfter(6)) {
        expect(m.fromMonths, greaterThan(6), reason: m.id);
      }
    });
  });

  group('what she has already written', () {
    test('marks a skill from her own words', () {
      final noted = milestonesNotedIn([milestone('Перевернулся сам!')]);
      expect(noted, contains('roll'));
    });

    test('catches both endings of the same word', () {
      expect(milestonesNotedIn([milestone('Перевернулась')]), contains('roll'));
      expect(milestonesNotedIn([milestone('Пошла!')]), contains('walk'));
      expect(milestonesNotedIn([milestone('Пошёл сам')]), contains('walk'));
    });

    test('reads the note as well as the title', () {
      final noted = milestonesNotedIn([
        milestone('Новое', description: 'сегодня сказал первое слово — мама'),
      ]);
      expect(noted, contains('firstWord'));
    });

    test('ignores anything that is not a milestone entry', () {
      // A feed whose note happens to say «сидит спокойно» is not an
      // announcement, and a tick against something that never happened is
      // worse than no tick at all.
      final feed = DevelopmentLog(
        id: 'f1',
        childId: 'c1',
        date: DateTime(2026, 6, 1),
        type: LogType.feeding,
        title: 'Кормление',
        description: 'сидит на руках спокойно',
      );
      expect(milestonesNotedIn([feed]), isEmpty);
    });

    test('is empty for a diary with nothing in it', () {
      expect(milestonesNotedIn(const []), isEmpty);
    });
  });
}
