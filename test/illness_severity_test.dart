import 'package:child_health_tracker/core/analytics/illness_stats.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:flutter_test/flutter_test.dart';

DevelopmentLog _illness(DateTime date, Severity? severity) => DevelopmentLog(
  id: '${date.millisecondsSinceEpoch}-${severity?.code}',
  childId: 'c1',
  date: date,
  type: LogType.illness,
  title: 'Болезнь',
  severity: severity,
);

DevelopmentLog _note(DateTime date) => DevelopmentLog(
  id: 'n-${date.millisecondsSinceEpoch}',
  childId: 'c1',
  date: date,
  type: LogType.note,
  title: 'Просто запись',
);

void main() {
  group('worstSeverityByDay', () {
    test('ignores everything that is not an illness entry', () {
      expect(worstSeverityByDay([_note(DateTime(2026, 7, 20))]), isEmpty);
      expect(worstSeverityByDay(const []), isEmpty);
    });

    test('the worst severity of the day wins', () {
      // A morning reading and an evening one: the heat map must show how bad
      // the day got, not whichever entry was written last.
      final result = worstSeverityByDay([
        _illness(DateTime(2026, 7, 20, 9), Severity.mild),
        _illness(DateTime(2026, 7, 20, 21), Severity.severe),
        _illness(DateTime(2026, 7, 20, 14), Severity.moderate),
      ]);
      expect(result[DateTime(2026, 7, 20)], Severity.severe);
      expect(result, hasLength(1));
    });

    test('the order entries arrive in does not change the result', () {
      final ascending = worstSeverityByDay([
        _illness(DateTime(2026, 7, 20, 8), Severity.mild),
        _illness(DateTime(2026, 7, 20, 20), Severity.moderate),
      ]);
      final descending = worstSeverityByDay([
        _illness(DateTime(2026, 7, 20, 20), Severity.moderate),
        _illness(DateTime(2026, 7, 20, 8), Severity.mild),
      ]);
      expect(ascending, descending);
    });

    test('an entry without a severity still counts as a sick day', () {
      final result = worstSeverityByDay([
        _illness(DateTime(2026, 7, 20), null),
      ]);
      expect(result[DateTime(2026, 7, 20)], Severity.mild);
    });

    test('a severity set on one day does not leak into another', () {
      final result = worstSeverityByDay([
        _illness(DateTime(2026, 7, 20), Severity.severe),
        _illness(DateTime(2026, 7, 21), Severity.mild),
      ]);
      expect(result[DateTime(2026, 7, 20)], Severity.severe);
      expect(result[DateTime(2026, 7, 21)], Severity.mild);
    });

    test('the time of day is discarded, the date is not', () {
      final result = worstSeverityByDay([
        _illness(DateTime(2026, 7, 20, 23, 59), Severity.moderate),
      ]);
      expect(result.keys.single, DateTime(2026, 7, 20));
    });
  });

  group('countIllnessEpisodes', () {
    test('no days means no episodes', () {
      expect(countIllnessEpisodes({}), 0);
    });

    test('consecutive days are one episode', () {
      expect(
        countIllnessEpisodes({
          DateTime(2026, 7, 1),
          DateTime(2026, 7, 2),
          DateTime(2026, 7, 3),
        }),
        1,
      );
    });

    test('a two-day gap is still the same episode', () {
      expect(
        countIllnessEpisodes({DateTime(2026, 7, 1), DateTime(2026, 7, 3)}),
        1,
      );
    });

    test('a longer gap starts a new episode', () {
      expect(
        countIllnessEpisodes({
          DateTime(2026, 7, 1),
          DateTime(2026, 7, 2),
          DateTime(2026, 7, 20),
        }),
        2,
      );
    });

    test('unsorted input gives the same answer', () {
      final days = {
        DateTime(2026, 7, 20),
        DateTime(2026, 7, 1),
        DateTime(2026, 7, 2),
      };
      expect(countIllnessEpisodes(days), 2);
    });
  });

  group('the two agree', () {
    test('every day in the severity map is one illness day', () {
      final logs = [
        _illness(DateTime(2026, 7, 20, 9), Severity.mild),
        _illness(DateTime(2026, 7, 20, 21), Severity.severe),
        _illness(DateTime(2026, 7, 22), Severity.moderate),
        _note(DateTime(2026, 7, 23)),
      ];
      final severities = worstSeverityByDay(logs);
      // The statistics and the calendar are drawn from one source, so a count
      // can never disagree with what the heat map shows.
      expect(severities.keys.toSet(), hasLength(2));
      expect(countIllnessEpisodes(severities.keys.toSet()), 1);
    });
  });
}
