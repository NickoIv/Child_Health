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

    test('stands all day, up to the hour the app goes quiet', () {
      // It is a date, so unlike the night — which stops being this morning's
      // news by lunchtime — it holds until nine, when everything stops.
      final child = childBornOn(DateTime(2026, 2, 14));
      final evening = noticedFor(child, const [], DateTime(2026, 6, 14, 20));
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

  group('at night', () {
    test('nothing is said at all, however true it is', () {
      // Nine in the evening to seven in the morning. She is holding the phone
      // over a cot and wants to put it down; the screen already goes red for
      // the same reason.
      final child = childBornOn(DateTime(2026, 2, 14));
      expect(noticedFor(child, const [], DateTime(2026, 6, 14, 23)), isNull);
      expect(noticedFor(child, const [], DateTime(2026, 6, 14, 4)), isNull);
      // And the same fact, in daylight, is said.
      expect(
        noticedFor(child, const [], DateTime(2026, 6, 14, 10))?.kind,
        NoticedKind.roundAge,
      );
    });
  });

  group('yesterday, while today is still empty', () {
    final child = childBornOn(DateTime(2026, 1, 5));
    final morning = DateTime(2026, 6, 20, 9);

    DevelopmentLog feed(DateTime at) => DevelopmentLog(
      id: 'f${at.millisecondsSinceEpoch}',
      childId: 'c1',
      date: at,
      type: LogType.feeding,
      title: 'Кормление',
    );

    test('is what the app opens on when midnight cleared the counters', () {
      final logs = [
        for (var i = 0; i < 8; i++)
          feed(DateTime(2026, 6, 19, 7 + i)),
        night(DateTime(2026, 6, 19, 21), 420),
      ];

      final noticed = noticedFor(child, logs, morning);
      expect(noticed?.kind, NoticedKind.yesterday);
      expect(noticed?.feedings, 8);
      expect(noticed?.minutes, 420);
    });

    test('is gone the moment anything is written down today', () {
      // No stored "already shown" day, and so nothing to go stale: it is true
      // exactly while today is empty, and the first feed ends it.
      final logs = [
        for (var i = 0; i < 8; i++)
          feed(DateTime(2026, 6, 19, 7 + i)),
        feed(DateTime(2026, 6, 20, 8)),
      ];
      expect(noticedFor(child, logs, morning), isNull);
    });

    test('says nothing about a yesterday that had no feeds in it', () {
      // A day she was not using the app. Handing a nought back is a
      // scoreboard, not news.
      expect(noticedFor(child, [night(DateTime(2026, 6, 19, 21), 400)],
          morning), isNull);
    });

    test('loses to a real observation', () {
      // The age and the night are about the child; yesterday's tally is the
      // app catching her up. Only one line shows, and it is not this one.
      final birthday = childBornOn(DateTime(2026, 2, 20));
      final logs = [for (var i = 0; i < 8; i++) feed(DateTime(2026, 6, 19, 7 + i))];
      expect(noticedFor(birthday, logs, morning)?.kind, NoticedKind.roundAge);
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
