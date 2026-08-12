import 'dart:convert';

import 'package:child_health_tracker/core/app_info.dart';
import 'package:child_health_tracker/core/backup/backup.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/models/medical_record.dart';
import 'package:child_health_tracker/models/reminder.dart';
import 'package:flutter_test/flutter_test.dart';

/// The copy she owns.
///
/// The app could import a diary from somebody else's app and could not hand
/// its own back. What is tested here is mostly that the file is *complete* —
/// a backup quietly missing one of two children is worse than no backup,
/// because it is trusted.
void main() {
  final at = DateTime(2026, 8, 14, 21, 30);

  Child child(String id, String name) => Child(
    id: id,
    parentUid: 'u1',
    name: name,
    birthDate: DateTime(2026, 2, 14),
    gender: Gender.male,
  );

  DevelopmentLog feed(String id, String childId) => DevelopmentLog(
    id: id,
    childId: childId,
    date: DateTime(2026, 8, 14, 9),
    type: LogType.feeding,
    title: 'Кормление',
    feedingSide: FeedingSide.left,
    durationMinutes: 15,
  );

  group('the file', () {
    test('carries every child, not only the selected one', () {
      // The failure this guards against is silent: a backup with one of two
      // children in it looks exactly like a backup.
      final backup = buildBackup(
        children: [child('a', 'Маус'), child('b', 'Аня')],
        logsByChild: {
          'a': [feed('l1', 'a')],
          'b': [feed('l2', 'b')],
        },
        recordsByChild: const {},
        remindersByChild: const {},
        at: at,
      );

      final children = backup['children']! as List;
      expect(children, hasLength(2));
      expect((children.first as Map)['logs'], hasLength(1));
      expect((children.last as Map)['logs'], hasLength(1));
    });

    test('keeps the ids, so it can be read back', () {
      final backup = buildBackup(
        children: [child('a', 'Маус')],
        logsByChild: {
          'a': [feed('l1', 'a')],
        },
        recordsByChild: const {},
        remindersByChild: const {},
        at: at,
      );

      final first = (backup['children']! as List).first as Map;
      expect(first['id'], 'a');
      expect(((first['logs']! as List).first as Map)['id'], 'l1');
    });

    test('says what wrote it and when', () {
      // A file found in three years should explain itself.
      final backup = buildBackup(
        children: const [],
        logsByChild: const {},
        recordsByChild: const {},
        remindersByChild: const {},
        at: at,
      );

      expect(backup['format'], backupFormatVersion);
      expect(backup['app_version'], AppInfo.version);
      expect(backup['exported_at'], at.toIso8601String());
    });

    test('is JSON that survives a round trip', () {
      final backup = buildBackup(
        children: [child('a', 'Маус')],
        logsByChild: {
          'a': [feed('l1', 'a')],
        },
        recordsByChild: {
          'a': [
            MedicalRecord(
              id: 'm1',
              childId: 'a',
              date: DateTime(2026, 7, 1),
              diagnosis: 'ОРВИ',
              doctor: 'Педиатр',
            ),
          ],
        },
        remindersByChild: {
          'a': [
            Reminder(
              id: 'r1',
              childId: 'a',
              type: ReminderType.medication,
              title: 'Сироп',
              scheduledTime: DateTime(2026, 8, 15, 9),
            ),
          ],
        },
        at: at,
      );

      final text = encodeBackup(backup);
      final decoded = jsonDecode(text) as Map<String, dynamic>;
      final first = (decoded['children']! as List).first as Map;

      expect(first['medical_records'], hasLength(1));
      expect(first['reminders'], hasLength(1));
      // Indented, because a person may open it to see what is in it.
      expect(text, contains('\n  '));
    });
  });

  group('the filename', () {
    test('names the child when there is one, and the day always', () {
      expect(
        backupFilename([child('a', 'Маус')], at),
        'дневник-Маус-2026-08-14.json',
      );
      expect(backupFilename(const [], at), 'дневник-2026-08-14.json');
    });

    test('survives a name a filesystem would object to', () {
      final awkward = child('a', 'Аня / Аня');
      final name = backupFilename([awkward], at);
      for (final bad in const ['/', r'\', ':', '*', '?', '"', '<', '>', '|']) {
        expect(name.contains(bad), isFalse, reason: bad);
      }
    });

    test('and two children share one file rather than a confused name', () {
      expect(
        backupFilename([child('a', 'Маус'), child('b', 'Аня')], at),
        'дневник-2026-08-14.json',
      );
    });
  });
}
