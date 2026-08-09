import 'package:child_health_tracker/core/import/diary_import.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reading a diary exported by another app.
///
/// The rule the whole importer is built on is that a row it cannot read is
/// skipped and counted, never guessed at: an import that quietly invents a
/// feed is worse than one that leaves twenty rows behind, because twenty
/// rows can be seen and a wrong one cannot. Most of what follows is that
/// rule, tested from both sides.
void main() {
  ImportPreview read(String text) => previewImport(text, childId: 'c1');

  group('the file itself', () {
    test('is read whichever separator it uses', () {
      for (final separator in [',', ';', '\t', '|']) {
        final text = [
          ['Дата', 'Тип'].join(separator),
          ['12.08.2026 09:15', 'Кормление'].join(separator),
        ].join('\n');

        final preview = read(text);
        expect(preview.entries, hasLength(1), reason: separator);
        expect(preview.entries.single.type, LogType.feeding);
      }
    });

    test('survives a BOM, CRLF endings and a trailing newline', () {
      final preview = read(
        '﻿Дата;Тип\r\n12.08.2026 09:15;Сон\r\n\r\n',
      );

      expect(preview.entries, hasLength(1));
      expect(preview.entries.single.type, LogType.sleep);
    });

    test('keeps a separator that is inside quotes', () {
      final preview = read(
        'Дата;Тип;Комментарий\n'
        '12.08.2026 09:15;Кормление;"хорошо ел, не срыгивал"',
      );

      expect(preview.entries.single.description, 'хорошо ел, не срыгивал');
    });

    test('reads a doubled quote as one quote', () {
      final preview = read(
        'Дата;Тип;Комментарий\n'
        '12.08.2026;Заметка;"сказал ""мама"""',
      );

      expect(preview.entries.single.description, contains('"мама"'));
    });

    test('a file with no header at all keeps its first row', () {
      // Common enough, and reading that row as a header would drop an entry
      // without telling anyone.
      final preview = read(
        '12.08.2026 09:15;Кормление\n13.08.2026 10:00;Сон',
      );

      expect(preview.entries, hasLength(2));
    });
  });

  group('the date', () {
    test('is read in every shape these files use', () {
      expect(parseWhen('12.08.2026'), DateTime(2026, 8, 12));
      expect(parseWhen('12/08/2026'), DateTime(2026, 8, 12));
      expect(parseWhen('2026-08-12'), DateTime(2026, 8, 12));
      expect(parseWhen('12.08.26'), DateTime(2026, 8, 12));
      expect(parseWhen('12.08.2026 09:15'), DateTime(2026, 8, 12, 9, 15));
      expect(parseWhen('2026-08-12T09:15:30'), DateTime(2026, 8, 12, 9, 15));
    });

    test('day comes first, because every Russian export writes it that way',
        () {
      expect(parseWhen('05.08.2026'), DateTime(2026, 8, 5));
    });

    test('refuses a day that does not exist instead of rolling it over', () {
      // DateTime(2026, 2, 31) is quietly the 3rd of March, which would put a
      // feed on a day it did not happen.
      expect(parseWhen('31.02.2026'), isNull);
      expect(parseWhen('12.13.2026'), isNull);
      expect(parseWhen('12.08.2026 25:00'), isNull);
      expect(parseWhen('вчера'), isNull);
      expect(parseWhen(''), isNull);
    });
  });

  group('the length', () {
    test('is minutes however the file writes them', () {
      expect(parseMinutes('25'), 25);
      expect(parseMinutes('25 мин'), 25);
      expect(parseMinutes('1 ч 20 мин'), 80);
      expect(parseMinutes('2ч'), 120);
      expect(parseMinutes('1:20'), 80);
      expect(parseMinutes('0:45:00'), 45);
      expect(parseMinutes('30 min'), 30);
    });

    test('is nothing when the cell is not a length', () {
      expect(parseMinutes(''), isNull);
      expect(parseMinutes('долго'), isNull);
    });
  });

  group('the kind', () {
    test('recognises a feed and which side it was', () {
      expect(readKind('Кормление грудью, левая')?.side, FeedingSide.left);
      expect(readKind('Кормление, правая')?.side, FeedingSide.right);
      expect(readKind('Смесь из бутылочки')?.side, FeedingSide.bottle);
      expect(readKind('Прикорм: каша')?.side, FeedingSide.solid);
      expect(readKind('Кормление')?.type, LogType.feeding);
    });

    test('recognises a nappy and what was in it', () {
      expect(readKind('Подгузник, мокрый')?.nappy, NappyKind.wet);
      expect(readKind('Подгузник, стул')?.nappy, NappyKind.dirty);
      expect(readKind('Подгузник: мокрый и стул')?.nappy, NappyKind.both);
    });

    test('recognises sleep, temperature and measurements', () {
      expect(readKind('Сон')?.type, LogType.sleep);
      expect(readKind('Температура')?.type, LogType.illness);
      expect(readKind('Вес')?.type, LogType.measurement);
      expect(readKind('Рост')?.type, LogType.measurement);
    });

    test('says nothing rather than guessing at a word it does not know', () {
      expect(readKind('Прогулка'), isNull);
      expect(readKind(''), isNull);
    });
  });

  group('what comes out', () {
    test('carries the time from its own column when the date has none', () {
      final preview = read(
        'Дата;Время;Тип;Длительность\n'
        '12.08.2026;09:15;Кормление грудью левая;15 мин',
      );

      final entry = preview.entries.single;
      expect(entry.date, DateTime(2026, 8, 12, 9, 15));
      expect(entry.feedingSide, FeedingSide.left);
      expect(entry.durationMinutes, 15);
      expect(entry.childId, 'c1');
      // Written with the model's own title, which is what the rest of the
      // app matches on.
      expect(entry.title, LogType.feeding.label);
    });

    test('a temperature keeps its reading', () {
      final preview = read(
        'Дата;Тип;Комментарий\n12.08.2026 20:00;Температура;37.8',
      );

      expect(preview.entries.single.metrics.temperatureC, 37.8);
    });

    test('a weight and a height are told apart', () {
      final preview = read(
        'Дата;Тип;Комментарий\n'
        '12.08.2026;Вес;8,4\n'
        '12.08.2026;Рост;72',
      );

      expect(preview.entries.first.metrics.weightKg, 8.4);
      expect(preview.entries.last.metrics.heightCm, 72);
    });

    test('a kind this app has no room for is kept as a note, not dropped', () {
      final preview = read(
        'Дата;Тип;Комментарий\n12.08.2026 11:00;Прогулка;два часа в парке',
      );

      final entry = preview.entries.single;
      expect(entry.type, LogType.note);
      expect(entry.description, contains('парк'));
      expect(preview.skipped, isEmpty);
    });

    test('a row with no readable date is skipped and reported by line', () {
      final preview = read(
        'Дата;Тип\n'
        '12.08.2026;Сон\n'
        'позавчера;Сон\n'
        '14.08.2026;Сон',
      );

      expect(preview.entries, hasLength(2));
      expect(preview.skipped, hasLength(1));
      // Line three of the file, counted the way a person counts.
      expect(preview.skipped.single.line, 3);
    });

    test('says which columns it understood', () {
      final preview = read(
        'Дата;Время;Событие;Продолжительность;Объём;Заметка;Ребёнок\n'
        '12.08.2026;09:15;Кормление;15;120;ок;Аиша',
      );

      expect(preview.roles[0], ColumnRole.date);
      expect(preview.roles[1], ColumnRole.time);
      expect(preview.roles[2], ColumnRole.kind);
      expect(preview.roles[3], ColumnRole.duration);
      expect(preview.roles[4], ColumnRole.amount);
      expect(preview.roles[5], ColumnRole.note);
      // A column it has no use for is named as unused rather than guessed at.
      expect(preview.roles[6], ColumnRole.ignored);
      expect(preview.entries.single.milkMl, 120);
    });

    test('finds the date column even when the header does not name it', () {
      final preview = read(
        'Когда;Что\n12.08.2026 09:15;Сон\n13.08.2026 10:00;Сон',
      );

      expect(preview.entries, hasLength(2));
    });

    test('counts by kind and spans the range it covers', () {
      final preview = read(
        'Дата;Тип\n'
        '12.08.2026 09:00;Кормление\n'
        '12.08.2026 12:00;Кормление\n'
        '13.08.2026 21:00;Сон',
      );

      expect(preview.countOf(LogType.feeding), 2);
      expect(preview.countOf(LogType.sleep), 1);
      expect(preview.range!.from, DateTime(2026, 8, 12, 9));
      expect(preview.range!.to, DateTime(2026, 8, 13, 21));
    });

    test('an empty file asks for nothing to be written', () {
      expect(read('').isEmpty, isTrue);
      expect(read('Дата;Тип\n').isEmpty, isTrue);
    });
  });
}
