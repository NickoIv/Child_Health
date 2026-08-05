import 'package:child_health_tracker/core/analytics/daily_care.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/core/l10n/labels.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

final _today = DateTime(2026, 7, 26);

DevelopmentLog _feed(int hour, [FeedingSide side = FeedingSide.left]) =>
    DevelopmentLog(
      id: 'f$hour',
      childId: 'c1',
      date: DateTime(_today.year, _today.month, _today.day, hour),
      type: LogType.feeding,
      title: 'Кормление',
      feedingSide: side,
    );

DevelopmentLog _nappy(int hour, NappyKind kind) => DevelopmentLog(
  id: 'n$hour${kind.code}',
  childId: 'c1',
  date: DateTime(_today.year, _today.month, _today.day, hour),
  type: LogType.nappy,
  title: 'Подгузник',
  nappyKind: kind,
);

DevelopmentLog _sleep(int hour, int minutes) => DevelopmentLog(
  id: 's$hour',
  childId: 'c1',
  date: DateTime(_today.year, _today.month, _today.day, hour),
  type: LogType.sleep,
  title: 'Сон',
  durationMinutes: minutes,
);

void main() {
  group('dailyCareFor', () {
    test('an empty day reports nothing', () {
      final care = dailyCareFor(const [], _today);
      expect(care.isEmpty, isTrue);
      expect(care.feedings, 0);
      expect(care.lastFeedingAt, isNull);
    });

    test('counts feeds and remembers the latest one', () {
      final care = dailyCareFor([_feed(3), _feed(14), _feed(7)], _today);
      expect(care.feedings, 3);
      expect(care.lastFeedingAt?.hour, 14);
    });

    test('a nappy with both counts on both tallies', () {
      // This is the whole reason NappyKind.both exists: one nappy, two facts.
      final care = dailyCareFor([_nappy(9, NappyKind.both)], _today);
      expect(care.wetNappies, 1);
      expect(care.dirtyNappies, 1);
    });

    test('separates wet from dirty', () {
      final care = dailyCareFor([
        _nappy(1, NappyKind.wet),
        _nappy(4, NappyKind.wet),
        _nappy(8, NappyKind.dirty),
        _nappy(12, NappyKind.both),
      ], _today);
      expect(care.wetNappies, 3);
      expect(care.dirtyNappies, 2);
    });

    test('sums sleep in minutes', () {
      final care = dailyCareFor([_sleep(2, 95), _sleep(13, 40)], _today);
      expect(care.sleepMinutes, 135);
    });

    test('ignores other days', () {
      final yesterday = DevelopmentLog(
        id: 'old',
        childId: 'c1',
        date: DateTime(2026, 7, 25, 10),
        type: LogType.feeding,
        title: 'Кормление',
        feedingSide: FeedingSide.left,
      );
      final care = dailyCareFor([yesterday, _feed(10)], _today);
      expect(care.feedings, 1);
    });

    test('ignores entry types that are not routine care', () {
      final milestone = DevelopmentLog(
        id: 'm',
        childId: 'c1',
        date: _today,
        type: LogType.milestone,
        title: 'Первая улыбка',
      );
      expect(dailyCareFor([milestone], _today).isEmpty, isTrue);
    });

    test('a nappy entry with no kind recorded is not counted', () {
      final incomplete = DevelopmentLog(
        id: 'x',
        childId: 'c1',
        date: _today,
        type: LogType.nappy,
        title: 'Подгузник',
      );
      final care = dailyCareFor([incomplete], _today);
      expect(care.wetNappies, 0);
      expect(care.dirtyNappies, 0);
    });

    test('minutesSinceFeeding measures from the latest feed', () {
      final care = dailyCareFor([_feed(6), _feed(9)], _today);
      final now = DateTime(2026, 7, 26, 11, 30);
      expect(care.minutesSinceFeeding(now), 150);
    });
  });

  group('targets from the knowledge base', () {
    test('mirror the thresholds the articles state', () {
      // "enough-milk": six or more wet nappies, 8-12 feeds in 24 hours.
      expect(CareTargets.minWetNappies, 6);
      expect(CareTargets.minFeedings, 8);
    });

    test('say nothing until the day is over', () {
      // Telling a mother at 9am that she is behind on feeds would be both
      // wrong and cruel.
      expect(
        CareTargets.wetNappyStatus(1, dayComplete: false),
        CareStatus.unknown,
      );
      expect(
        CareTargets.feedingStatus(2, dayComplete: false),
        CareStatus.unknown,
      );
    });

    test('flag a genuinely low count once the day is complete', () {
      expect(
        CareTargets.wetNappyStatus(3, dayComplete: true),
        CareStatus.watch,
      );
      expect(
        CareTargets.wetNappyStatus(6, dayComplete: true),
        CareStatus.onTrack,
      );
      expect(
        CareTargets.feedingStatus(7, dayComplete: true),
        CareStatus.watch,
      );
      expect(
        CareTargets.feedingStatus(8, dayComplete: true),
        CareStatus.onTrack,
      );
    });
  });

  group('durations', () {
    // The unlocalized formatter is gone; the words come from the ARB now, so
    // the shape is asserted in every language rather than only in Russian.
    test('read as hours and minutes, in whichever language', () async {
      for (final locale in supportedLocales) {
        final l = await AppLocalizations.delegate.load(locale);
        expect(localizedDuration(l, 0), '—');
        expect(localizedDuration(l, 45), contains('45'));
        expect(localizedDuration(l, 60), contains('1'));

        final long = localizedDuration(l, 135);
        expect(long, contains('2'));
        expect(long, contains('15'));
      }
    });
  });
}
