import 'package:child_health_tracker/core/voice/voice_commands.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:flutter_test/flutter_test.dart';

/// «Когда голосом диктую, дата и время должны записываться сразу — как если
/// вручную набирать.»
///
/// A dictated entry was always stamped at the moment the microphone stopped,
/// so «покормила вчера в девять вечера» landed on today and had to be corrected
/// by hand — which is the work the microphone existed to save.
///
/// Past-biased throughout: these are records of what happened. The one thing
/// worse than not hearing a date is hearing one that was not said, so anything
/// unrecognised stays null and the entry is stamped now exactly as before.
void main() {
  // A Thursday morning. Late enough that "yesterday evening" is unambiguous.
  final now = DateTime(2026, 8, 6, 10, 30);

  DateTime? moment(String heard) => spokenMoment(heard, now: now);

  group('the day', () {
    test('yesterday, today, tomorrow and their neighbours', () {
      expect(moment('покормила вчера')!.day, 5);
      expect(moment('позавчера был подгузник')!.day, 4);
      expect(moment('сегодня поспал')!.day, 6);
      expect(moment('завтра приём')!.day, 7);
      expect(moment('послезавтра приём')!.day, 8);
    });

    test('a day without a clock keeps the current time of day', () {
      final at = moment('вчера покормила')!;
      expect(at.hour, 10);
      expect(at.minute, 30);
    });

    test('a named date', () {
      final at = moment('покормила 3 августа')!;
      expect(at.month, 8);
      expect(at.day, 3);
      expect(at.year, 2026);
    });

    test('a date still ahead belongs to last year', () {
      // Said in August, «31 декабря» is four months back, not four ahead.
      final at = moment('31 декабря был приём')!;
      expect(at.year, 2025);
      expect(at.month, 12);
    });

    test('a typed date, as keyboard dictation produces it', () {
      final at = moment('температура 04.08')!;
      expect(at.month, 8);
      expect(at.day, 4);
    });
  });

  group('the clock', () {
    test('an exact time', () {
      final at = moment('покормила в 14:30')!;
      expect(at.hour, 14);
      expect(at.minute, 30);
      // Half past ten in the morning: half past two has not happened yet, so
      // it is yesterday's. A diary records what already happened.
      expect(at.day, 5);
    });

    test('and today when it has already passed', () {
      final at = moment('покормила в 08:15')!;
      expect(at.hour, 8);
      expect(at.day, 6);
    });

    test('a time that has not happened yet is yesterday', () {
      // Said at half past ten, «в девять вечера» is last night.
      final at = moment('покормила в девять вечера')!;
      expect(at.hour, 21);
      expect(at.day, 5);
    });

    test('but not when she named the day herself', () {
      final at = moment('завтра в 9 утра приём')!;
      expect(at.hour, 9);
      expect(at.day, 7);
    });

    test('morning, afternoon, evening and night', () {
      expect(moment('в 9 утра')!.hour, 9);
      expect(moment('в 2 дня')!.hour, 14);
      expect(moment('в 8 вечера')!.hour, 20);
      expect(moment('в 3 ночи')!.hour, 3);
      expect(moment('в полдень')!.hour, 12);
    });

    test('a spoken numeral', () {
      expect(moment('в восемь вечера')!.hour, 20);
      expect(moment('в семь утра')!.hour, 7);
    });
  });

  group('"ago"', () {
    test('hours and minutes', () {
      expect(moment('покормила час назад'), now.subtract(
        const Duration(hours: 1),
      ));
      expect(moment('два часа назад'), now.subtract(
        const Duration(hours: 2),
      ));
      expect(moment('20 минут назад'), now.subtract(
        const Duration(minutes: 20),
      ));
      expect(moment('полчаса назад'), now.subtract(
        const Duration(minutes: 30),
      ));
    });

    test('it wins over a clock time in the same sentence', () {
      expect(moment('в 14:30 нет, час назад'), now.subtract(
        const Duration(hours: 1),
      ));
    });
  });

  group('what it refuses to hear', () {
    test('a sentence with no moment in it', () {
      expect(moment('покормила левой грудью'), isNull);
      expect(moment('подгузник мокрый'), isNull);
      expect(moment('температура 37.8'), isNull);
    });

    test('a duration is not a time', () {
      // «поспал 2 часа» is how long, not when. Reading it as two o'clock
      // would move the entry by most of a day.
      expect(moment('поспал 2 часа'), isNull);
      expect(moment('кормила 15 минут'), isNull);
    });

    test('millilitres are not a clock', () {
      expect(moment('бутылочка 90 мл'), isNull);
    });
  });

  group('the entry it produces', () {
    test('is filed on the day she named', () {
      final command = parseVoiceCommand('покормила вчера в 21:00', now: now);
      final entry = voiceLog(command, childId: 'demo', at: now);

      expect(entry.type, LogType.feeding);
      expect(entry.date, DateTime(2026, 8, 5, 21));
    });

    test('is filed now when she named nothing', () {
      final command = parseVoiceCommand('покормила левой', now: now);
      final entry = voiceLog(command, childId: 'demo', at: now);

      expect(command.at, isNull);
      expect(entry.date, now);
    });

    test('keeps the duration it heard alongside the moment', () {
      final command = parseVoiceCommand('вчера поспал 2 часа', now: now);
      final entry = voiceLog(command, childId: 'demo', at: now);

      expect(entry.type, LogType.sleep);
      expect(entry.durationMinutes, 120);
      expect(entry.date.day, 5);
    });

    test('a temperature keeps its reading and its day', () {
      final command = parseVoiceCommand(
        'вчера температура 38.2',
        now: now,
      );
      final entry = voiceLog(command, childId: 'demo', at: now);

      expect(entry.metrics.temperatureC, 38.2);
      expect(entry.type, LogType.illness);
      expect(entry.date.day, 5);
    });
  });
}
