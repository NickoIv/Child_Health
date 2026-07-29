import 'dart:async';

import 'package:uuid/uuid.dart';

import '../models/child.dart';
import '../models/development_log.dart';
import '../models/medical_record.dart';
import '../models/reminder.dart';
import 'repositories.dart';
import 'seed_data.dart';

const _uuid = Uuid();

/// Keeps a list in memory and republishes it on every mutation.
///
/// Sorting lives here rather than in the widgets so the Firestore
/// implementation can push the same ordering down into a query.
class Store<T> {
  Store(this._items, this._compare);

  final List<T> _items;
  final int Function(T, T) _compare;
  final _controller = StreamController<List<T>>.broadcast();

  Stream<List<T>> watch(bool Function(T) where) {
    // A late subscriber must still see the current state, so the stream is
    // the current snapshot followed by every later one.
    return Stream<List<T>>.multi((listener) {
      listener.add(_snapshot(where));
      final sub = _controller.stream
          .map((_) => _snapshot(where))
          .listen(listener.add);
      listener.onCancel = sub.cancel;
    });
  }

  List<T> _snapshot(bool Function(T) where) {
    final result = _items.where(where).toList()..sort(_compare);
    return List.unmodifiable(result);
  }

  void mutate(void Function(List<T>) action) {
    action(_items);
    _controller.add(_items);
  }

  void dispose() => _controller.close();
}

/// In-memory backing store for the whole app.
///
/// Data lives for the lifetime of the session only — reloading the page
/// resets it to [buildSeedData]. Replaced by Firestore once the project is
/// configured; see `docs` in the README.
class MemoryDatabase {
  MemoryDatabase._(this.children, this.logs, this.records, this.reminders);

  factory MemoryDatabase.seeded(String parentUid) {
    final seed = buildSeedData(parentUid);
    return MemoryDatabase._(
      Store<Child>(seed.children, (a, b) => a.birthDate.compareTo(b.birthDate)),
      Store<DevelopmentLog>(seed.logs, (a, b) => b.date.compareTo(a.date)),
      Store<MedicalRecord>(seed.records, (a, b) => b.date.compareTo(a.date)),
      Store<Reminder>(
        seed.reminders,
        (a, b) => a.scheduledTime.compareTo(b.scheduledTime),
      ),
    );
  }

  final Store<Child> children;
  final Store<DevelopmentLog> logs;
  final Store<MedicalRecord> records;
  final Store<Reminder> reminders;

  void dispose() {
    children.dispose();
    logs.dispose();
    records.dispose();
    reminders.dispose();
  }
}

class MemoryChildRepository implements ChildRepository {
  MemoryChildRepository(this._db);

  final MemoryDatabase _db;

  @override
  Stream<List<Child>> watchChildren(String parentUid) =>
      _db.children.watch((c) => c.parentUid == parentUid);

  @override
  Future<Child> add({
    required String parentUid,
    required String name,
    required DateTime birthDate,
    required Gender gender,
  }) async {
    final child = Child(
      id: _uuid.v4(),
      parentUid: parentUid,
      name: name,
      birthDate: birthDate,
      gender: gender,
    );
    _db.children.mutate((items) => items.add(child));
    return child;
  }

  @override
  Future<void> update(Child child) async {
    _db.children.mutate((items) {
      final i = items.indexWhere((c) => c.id == child.id);
      if (i != -1) items[i] = child;
    });
  }

  @override
  Future<void> delete(String childId) async {
    _db.children.mutate((items) => items.removeWhere((c) => c.id == childId));
    // Cascade, mirroring the cleanup a Cloud Function would do server-side.
    _db.logs.mutate((items) => items.removeWhere((l) => l.childId == childId));
    _db.records.mutate(
      (items) => items.removeWhere((r) => r.childId == childId),
    );
    _db.reminders.mutate(
      (items) => items.removeWhere((r) => r.childId == childId),
    );
  }
}

class MemoryDevelopmentLogRepository implements DevelopmentLogRepository {
  MemoryDevelopmentLogRepository(this._db);

  final MemoryDatabase _db;

  @override
  Stream<List<DevelopmentLog>> watchLogs(String childId) =>
      _db.logs.watch((l) => l.childId == childId);

  @override
  Future<DevelopmentLog> add(DevelopmentLog log) async {
    final saved = log.id.isEmpty ? log.copyWithId(_uuid.v4()) : log;
    _db.logs.mutate((items) => items.add(saved));
    return saved;
  }

  @override
  Future<void> update(DevelopmentLog log) async {
    _db.logs.mutate((items) {
      final i = items.indexWhere((l) => l.id == log.id);
      if (i != -1) items[i] = log;
    });
  }

  @override
  Future<void> delete(String logId) async {
    _db.logs.mutate((items) => items.removeWhere((l) => l.id == logId));
  }
}

class MemoryMedicalRecordRepository implements MedicalRecordRepository {
  MemoryMedicalRecordRepository(this._db);

  final MemoryDatabase _db;

  @override
  Stream<List<MedicalRecord>> watchRecords(String childId) =>
      _db.records.watch((r) => r.childId == childId);

  @override
  Future<MedicalRecord> add(MedicalRecord record) async {
    final saved = record.id.isEmpty ? record.copyWithId(_uuid.v4()) : record;
    _db.records.mutate((items) => items.add(saved));
    return saved;
  }

  @override
  Future<void> update(MedicalRecord record) async {
    _db.records.mutate((items) {
      final i = items.indexWhere((r) => r.id == record.id);
      if (i != -1) items[i] = record;
    });
  }

  @override
  Future<void> delete(String recordId) async {
    _db.records.mutate((items) => items.removeWhere((r) => r.id == recordId));
  }
}

class MemoryReminderRepository implements ReminderRepository {
  MemoryReminderRepository(this._db);

  final MemoryDatabase _db;

  @override
  Stream<List<Reminder>> watchReminders(String childId) =>
      _db.reminders.watch((r) => r.childId == childId);

  @override
  Future<Reminder> add(Reminder reminder) async {
    final saved =
        reminder.id.isEmpty ? reminder.copyWithId(_uuid.v4()) : reminder;
    _db.reminders.mutate((items) => items.add(saved));
    return saved;
  }

  @override
  Future<void> update(Reminder reminder) async {
    _db.reminders.mutate((items) {
      final i = items.indexWhere((r) => r.id == reminder.id);
      if (i != -1) items[i] = reminder;
    });
  }

  @override
  Future<void> delete(String reminderId) async {
    _db.reminders.mutate(
      (items) => items.removeWhere((r) => r.id == reminderId),
    );
  }
}
