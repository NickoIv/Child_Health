import 'package:child_health_tracker/data/memory_repository.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/models/reminder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemoryDatabase db;

  setUp(() => db = MemoryDatabase.seeded('parent-1'));
  tearDown(() => db.dispose());

  group('MemoryChildRepository', () {
    test('a new subscriber immediately receives the current state', () async {
      final repo = MemoryChildRepository(db);
      final children = await repo.watchChildren('parent-1').first;
      expect(children, isNotEmpty, reason: 'seed data should be visible');
    });

    test('only returns children of the given parent', () async {
      final repo = MemoryChildRepository(db);
      await repo.add(
        parentUid: 'someone-else',
        name: 'Чужой',
        birthDate: DateTime(2025, 1, 1),
        gender: Gender.female,
      );
      final mine = await repo.watchChildren('parent-1').first;
      expect(mine.any((c) => c.name == 'Чужой'), isFalse);
    });

    test('add emits an updated list to existing listeners', () async {
      final repo = MemoryChildRepository(db);
      final stream = repo.watchChildren('parent-1');
      final before = (await stream.first).length;

      final updates = stream.skip(1).first;
      await repo.add(
        parentUid: 'parent-1',
        name: 'Второй ребёнок',
        birthDate: DateTime(2026, 1, 1),
        gender: Gender.female,
      );

      final after = await updates;
      expect(after, hasLength(before + 1));
      expect(after.any((c) => c.name == 'Второй ребёнок'), isTrue);
    });

    test('update replaces the stored child', () async {
      final repo = MemoryChildRepository(db);
      final child = (await repo.watchChildren('parent-1').first).first;
      await repo.update(child.copyWith(name: 'Переименован'));
      final reloaded = (await repo.watchChildren('parent-1').first).first;
      expect(reloaded.name, 'Переименован');
      expect(reloaded.id, child.id);
    });

    test('delete cascades to logs, records and reminders', () async {
      final childRepo = MemoryChildRepository(db);
      final logRepo = MemoryDevelopmentLogRepository(db);
      final reminderRepo = MemoryReminderRepository(db);

      final child = (await childRepo.watchChildren('parent-1').first).first;
      expect(await logRepo.watchLogs(child.id).first, isNotEmpty);
      expect(await reminderRepo.watchReminders(child.id).first, isNotEmpty);

      await childRepo.delete(child.id);

      expect(await childRepo.watchChildren('parent-1').first, isEmpty);
      expect(await logRepo.watchLogs(child.id).first, isEmpty);
      expect(await reminderRepo.watchReminders(child.id).first, isEmpty);
    });
  });

  group('MemoryDevelopmentLogRepository', () {
    test('assigns an id when the draft has none', () async {
      final repo = MemoryDevelopmentLogRepository(db);
      final child = (await MemoryChildRepository(db)
              .watchChildren('parent-1')
              .first)
          .first;
      final saved = await repo.add(
        DevelopmentLog(
          id: '',
          childId: child.id,
          date: DateTime(2026, 7, 1),
          type: LogType.note,
          title: 'Без id',
        ),
      );
      expect(saved.id, isNotEmpty);
    });

    test('returns logs newest first', () async {
      final repo = MemoryDevelopmentLogRepository(db);
      final child = (await MemoryChildRepository(db)
              .watchChildren('parent-1')
              .first)
          .first;
      final logs = await repo.watchLogs(child.id).first;
      for (var i = 1; i < logs.length; i++) {
        expect(
          logs[i - 1].date.isBefore(logs[i].date),
          isFalse,
          reason: 'entry $i breaks the descending order',
        );
      }
    });

    test('delete removes the entry', () async {
      final repo = MemoryDevelopmentLogRepository(db);
      final child = (await MemoryChildRepository(db)
              .watchChildren('parent-1')
              .first)
          .first;
      final logs = await repo.watchLogs(child.id).first;
      await repo.delete(logs.first.id);
      final after = await repo.watchLogs(child.id).first;
      expect(after.any((l) => l.id == logs.first.id), isFalse);
      expect(after, hasLength(logs.length - 1));
    });
  });

  group('MemoryReminderRepository', () {
    test('reminders come back in chronological order', () async {
      final repo = MemoryReminderRepository(db);
      final child = (await MemoryChildRepository(db)
              .watchChildren('parent-1')
              .first)
          .first;
      final reminders = await repo.watchReminders(child.id).first;
      for (var i = 1; i < reminders.length; i++) {
        expect(
          reminders[i - 1].scheduledTime.isAfter(reminders[i].scheduledTime),
          isFalse,
        );
      }
    });

    test('update toggles completion', () async {
      final repo = MemoryReminderRepository(db);
      final child = (await MemoryChildRepository(db)
              .watchChildren('parent-1')
              .first)
          .first;
      final first = (await repo.watchReminders(child.id).first)
          .firstWhere((r) => !r.isCompleted);
      await repo.update(first.copyWith(isCompleted: true));
      final reloaded = (await repo.watchReminders(child.id).first)
          .firstWhere((r) => r.id == first.id);
      expect(reloaded.isCompleted, isTrue);
    });

    test('seeded plan contains the national vaccination schedule', () async {
      final repo = MemoryReminderRepository(db);
      final child = (await MemoryChildRepository(db)
              .watchChildren('parent-1')
              .first)
          .first;
      final reminders = await repo.watchReminders(child.id).first;
      final vaccinations =
          reminders.where((r) => r.type == ReminderType.vaccination);
      expect(vaccinations, isNotEmpty);
      expect(vaccinations.every((r) => r.id.isNotEmpty), isTrue);
    });
  });
}
