import '../models/child.dart';
import '../models/development_log.dart';
import '../models/medical_record.dart';
import '../models/reminder.dart';

/// Contracts the UI depends on. The in-memory implementation backs the app
/// today; a Firestore-backed one drops in behind the same interfaces without
/// touching a single widget.
///
/// Every read returns a [Stream] so that swapping in `snapshots()` from
/// cloud_firestore is a change of implementation only.
abstract class ChildRepository {
  Stream<List<Child>> watchChildren(String parentUid);

  Future<Child> add({
    required String parentUid,
    required String name,
    required DateTime birthDate,
    required Gender gender,
  });

  Future<void> update(Child child);

  Future<void> delete(String childId);
}

abstract class DevelopmentLogRepository {
  Stream<List<DevelopmentLog>> watchLogs(String childId);

  Future<DevelopmentLog> add(DevelopmentLog log);

  Future<void> update(DevelopmentLog log);

  Future<void> delete(String logId);
}

abstract class MedicalRecordRepository {
  Stream<List<MedicalRecord>> watchRecords(String childId);

  Future<MedicalRecord> add(MedicalRecord record);

  Future<void> update(MedicalRecord record);

  Future<void> delete(String recordId);
}

abstract class ReminderRepository {
  Stream<List<Reminder>> watchReminders(String childId);

  Future<Reminder> add(Reminder reminder);

  Future<void> update(Reminder reminder);

  Future<void> delete(String reminderId);
}
