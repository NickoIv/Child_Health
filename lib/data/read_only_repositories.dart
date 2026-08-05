import 'dart:typed_data';

import '../models/child.dart';
import '../models/development_log.dart';
import '../models/medical_record.dart';
import '../models/photo.dart';
import '../models/reminder.dart';
import 'photo_repository.dart';
import 'repositories.dart';

/// Raised when a viewer's client tries to write.
///
/// It should never reach a parent's screen — the interface hides or locks
/// every control that could cause one. It exists because "the interface hides
/// it" is not a guarantee, and a guarantee is what read-only access has to be:
/// a route missed in a refactor, a stale sheet left open when access is
/// revoked, a deep link. The security rules refuse the same writes from the
/// far end; this refuses them before they cost a round trip.
class ReadOnlyAccessException implements Exception {
  const ReadOnlyAccessException(this.what);

  /// Which repository was written to, for the log. Never shown to anyone.
  final String what;

  @override
  String toString() => 'ReadOnlyAccessException: $what is read-only';
}

Never _refuse(String what) => throw ReadOnlyAccessException(what);

/// Reads pass through, writes are refused.
///
/// Wrapping rather than a flag inside each repository: a flag is one `if`
/// away from being forgotten in the next method somebody adds, whereas a
/// wrapper that does not implement a write cannot compile without one.
class ReadOnlyChildRepository implements ChildRepository {
  const ReadOnlyChildRepository(this._inner);

  final ChildRepository _inner;

  @override
  Stream<List<Child>> watchChildren(String parentUid) =>
      _inner.watchChildren(parentUid);

  @override
  Future<Child> add({
    required String parentUid,
    required String name,
    required DateTime birthDate,
    required Gender gender,
  }) async => _refuse('children');

  @override
  Future<void> update(Child child) async => _refuse('children');

  @override
  Future<void> delete(String childId) async => _refuse('children');
}

class ReadOnlyLogRepository implements DevelopmentLogRepository {
  const ReadOnlyLogRepository(this._inner);

  final DevelopmentLogRepository _inner;

  @override
  Stream<List<DevelopmentLog>> watchLogs(String childId) =>
      _inner.watchLogs(childId);

  @override
  Future<DevelopmentLog> add(DevelopmentLog log) async => _refuse('logs');

  @override
  Future<void> update(DevelopmentLog log) async => _refuse('logs');

  @override
  Future<void> delete(String logId) async => _refuse('logs');
}

class ReadOnlyMedicalRecordRepository implements MedicalRecordRepository {
  const ReadOnlyMedicalRecordRepository(this._inner);

  final MedicalRecordRepository _inner;

  @override
  Stream<List<MedicalRecord>> watchRecords(String childId) =>
      _inner.watchRecords(childId);

  @override
  Future<MedicalRecord> add(MedicalRecord record) async =>
      _refuse('medical records');

  @override
  Future<void> update(MedicalRecord record) async => _refuse('medical records');

  @override
  Future<void> delete(String recordId) async => _refuse('medical records');
}

class ReadOnlyReminderRepository implements ReminderRepository {
  const ReadOnlyReminderRepository(this._inner);

  final ReminderRepository _inner;

  @override
  Stream<List<Reminder>> watchReminders(String childId) =>
      _inner.watchReminders(childId);

  @override
  Future<Reminder> add(Reminder reminder) async => _refuse('reminders');

  @override
  Future<void> update(Reminder reminder) async => _refuse('reminders');

  @override
  Future<void> delete(String reminderId) async => _refuse('reminders');
}

/// Photos stay visible and stay unwritable.
///
/// Viewing is the whole point of the invitation — the father is here to see
/// the child, and the photographs are most of what that means.
class ReadOnlyPhotoRepository implements PhotoRepository {
  const ReadOnlyPhotoRepository(this._inner);

  final PhotoRepository _inner;

  @override
  Future<Photo?> byId(String photoId) => _inner.byId(photoId);

  @override
  Future<Photo> upload({
    required String childId,
    required Uint8List bytes,
    String caption = '',
  }) async => _refuse('photos');

  @override
  Future<void> delete(String photoId) async => _refuse('photos');
}
