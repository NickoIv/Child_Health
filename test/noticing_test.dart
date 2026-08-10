import 'package:child_health_tracker/core/care/greeting.dart';
import 'package:child_health_tracker/core/care/noticing.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:flutter_test/flutter_test.dart';

/// The sentence at the top of the home screen, and what it is allowed to say.
///
/// The rule this suite exists to keep: the app may say something true or it
/// may say nothing. What it may not do is say something warm on a schedule —
/// a card that praises her every morning has stopped reading her days and
/// started reading a calendar, and she works that out faster than we would.
void main() {
  Child childBornOn(DateTime birth) => Child(
    id: 'c1',
    parentUid: 'u1',
    name: 'Миша',
    birthDate: birth,
    gender: Gender.male,
  );

  DevelopmentLog night(DateTime at, int minutes, {int wakings = 1}) =>
      DevelopmentLog(
        id: 'n${at.millisecondsSinceEpoch}',
        childId: 'c1',
        date: at,
        type: LogType.sleep,
        title: 'Ночной сон',
        durationMinutes: minutes,
        nightWakings: wakings,
      );

  group('an exact age', () {
    test('is noticed on the day and not the day before or after', () {
      final child = childBornOn(DateTime(2026, 2, 14));

      final on = noticedFor(child, const [], DateTime(2026, 6, 14, 9));
      expect(on?.kind, NoticedKind.roundAge);
      expect(on?.months, 4);

      expect(noticedFor(child, const [], DateTime(2026, 6, 13, 9)), isNull);
      expect(noticedFor(child, const [], DateTime(2026, 6, 15, 9)), isNull);
    });

    test('lands on the last day of a month too short to hold it', () {
      // Born on the 31st. There is no 31st of April, and skipping it would
      // mean a child born at the end of a long month has a birthday every
      // second month.
      final child = childBornOn(DateTime(2026, 1, 31));

      final on = noticedFor(child, const [], DateTime(2026, 4, 30, 9));
      expect(on?.kind, NoticedKind.roundAge);
      expect(on?.months, 2);
    });

    test('says nothing on the day she was born, or in the first month', () {
      final child = childBornOn(DateTime(2026, 2, 14));
      // «Ровно ноль месяцев» is not a sentence anybody says.
      expect(noticedFor(child, const [], DateTime(2026, 2, 14, 9)), isNull);
    });

    test('is not said in the evening of a day it was already true', () {
      // It is a date, so it stands all day — unlike the night, which stops
      // being this morning's news by lunchtime.
      final child = childBornOn(DateTime(2026, 2, 14));
      final evening = noticedFor(child, const [], DateTime(2026, 6, 14, 21));
      expect(evening?.kind, NoticedKind.roundAge);
    });
  });

  group('the longest night', () {
    // A child whose birthday is nowhere near, so the age never wins the slot.
    final child = childBornOn(DateTime(2026, 1, 5));
    final morning = DateTime(2026, 6, 20, 8);

    List<DevelopmentLog> nightsOf(List<int> minutes) => [
      for (var i = 0; i < minutes.length; i++)
        night(morning.subtract(Duration(days: i + 1, hours: 2)), minutes[i]),
    ];

    test('is said when it beat the month before it', () {
      final logs = [
        night(morning.subtract(const Duration(hours: 10)), 500),
        ...nightsOf([380, 400, 360, 420, 390, 410]),
      ];

      final noticed = noticedFor(child, logs, morning);
      expect(noticed?.kind, NoticedKind.longestNight);
      expect(noticed?.minutes, 500);
    });

    test('is not said for a night that won by six minutes', () {
      // Nobody noticed those six minutes, and telling her she did is how the
      // next sentence stops being believed.
      final logs = [
        night(morning.subtract(const Duration(hours: 10)), 426),
        ...nightsOf([380, 400, 360, 420, 390, 410]),
      ];
      expect(noticedFor(child, logs, morning), isNull);
    });

    test('waits until there are nights to compare it with', () {
      final logs = [
        night(morning.subtract(const Duration(hours: 10)), 600),
        ...nightsOf([300, 320]),
      ];
      // A first week where every night is the best night so far would be six
      // congratulations in a row and no information.
      expect(noticedFor(child, logs, morning), isNull);
    });

    test('stops being this morning\'s news by the afternoon', () {
      final logs = [
        night(morning.subtract(const Duration(hours: 10)), 500),
        ...nightsOf([380, 400, 360, 420, 390, 410]),
      ];
      final afternoon = DateTime(2026, 6, 20, 15);
      expect(noticedFor(child, logs, afternoon), isNull);
    });
  });

  group('and on an ordinary day', () {
    test('there is nothing to say, and it says nothing', () {
      // Which is most days, and is the whole point: the phrase of the day
      // shows instead, and a real observation stays worth reading because it
      // is not competing with one every morning.
      final child = childBornOn(DateTime(2026, 1, 5));
      expect(noticedFor(child, const [], DateTime(2026, 6, 20, 9)), isNull);
    });
  });

  group('the greeting', () {
    test('uses her first name and only her first name', () async {
      final l = await AppLocalizations.delegate.load(defaultLocale);
      final morning = DateTime(2026, 6, 20, 9);

      expect(greetingFor(l, morning, name: 'Анна Иванова'), contains('Анна'));
      expect(
        greetingFor(l, morning, name: 'Анна Иванова'),
        isNot(contains('Иванова')),
      );
    });

    test('is the plain one when she never gave a name', () async {
      final l = await AppLocalizations.delegate.load(defaultLocale);
      final morning = DateTime(2026, 6, 20, 9);

      expect(greetingFor(l, morning), l.greetingMorning);
      expect(greetingFor(l, morning, name: '   '), l.greetingMorning);
    });
  });
}
