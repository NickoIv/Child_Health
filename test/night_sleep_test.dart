import 'package:child_health_tracker/core/analytics/daily_care.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:flutter_test/flutter_test.dart';

DevelopmentLog night({
  required DateTime asleep,
  required int minutes,
  int wakings = 2,
  int feeds = 1,
}) => DevelopmentLog(
  id: 'n1',
  childId: 'c1',
  date: asleep,
  type: LogType.sleep,
  title: 'Ночной сон',
  durationMinutes: minutes,
  nightWakings: wakings,
  nightFeeds: feeds,
);

void main() {
  final asleep = DateTime(2026, 8, 1, 21);

  group('a night', () {
    test('is a sleep entry, so nothing else has to know about it', () {
      final log = night(asleep: asleep, minutes: 540);

      expect(log.type, LogType.sleep);
      expect(log.durationMinutes, 540);
      expect(log.isNightSleep, isTrue);
    });

    test('survives a round trip through Firestore', () {
      final restored = DevelopmentLog.fromMap(
        'n1',
        night(asleep: asleep, minutes: 540).toMap(),
      );

      expect(restored.nightWakings, 2);
      expect(restored.nightFeeds, 1);
      expect(restored.durationMinutes, 540);
      expect(restored.date, asleep);
    });

    test('says what happened in one line', () {
      final summary = night(asleep: asleep, minutes: 540).routineSummary;

      expect(summary, contains('9 ч'));
      expect(summary, contains('пробуждений: 2'));
      expect(summary, contains('кормлений: 1'));
    });

    test('counts towards the day\'s sleep like any other', () {
      final care = dailyCareFor([
        night(asleep: DateTime(2026, 8, 1, 21), minutes: 540),
        DevelopmentLog(
          id: 'nap',
          childId: 'c1',
          date: DateTime(2026, 8, 1, 13),
          type: LogType.sleep,
          title: 'Сон',
          durationMinutes: 60,
        ),
      ], DateTime(2026, 8, 1, 23));

      expect(care.sleepMinutes, 600);
    });
  });

  group('an entry written before night sleep existed', () {
    final legacy = DevelopmentLog.fromMap('old', {
      'child_id': 'c1',
      'date': '2025-05-01T13:00:00.000',
      'type': 'sleep',
      'title': 'Сон',
      'duration_minutes': 90,
    });

    test('reads back with no night fields and is not mistaken for one', () {
      expect(legacy.nightWakings, isNull);
      expect(legacy.nightFeeds, isNull);
      expect(legacy.isNightSleep, isFalse);
      expect(legacy.durationMinutes, 90);
    });

    test('writes back without inventing them', () {
      final map = legacy.toMap();

      expect(map.containsKey('night_wakings'), isFalse);
      expect(map.containsKey('night_feeds'), isFalse);
    });

    test('still summarises as it always did', () {
      expect(legacy.routineSummary, '1 ч 30 мин');
    });
  });
}
