import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/repositories.dart';
import '../models/child.dart';
import '../models/development_log.dart';
import '../models/medical_record.dart';
import '../models/reminder.dart';

/// Collection names, matching section 4 of the specification.
abstract final class Collections {
  static const users = 'users';
  static const children = 'children';
  static const logs = 'development_logs';
  static const records = 'medical_records';
  static const reminders = 'reminders';
}

/// Every document carries the owning parent's uid, not just the child id.
///
/// The spec's schema puts `parent_uid` on `children` only, but without it on
/// the leaf collections a security rule has to `get()` the parent child
/// document on every single read — one extra billed read per document and a
/// rule that is easy to get wrong. Denormalising one field makes the rule a
/// straight field comparison. It is written by the repository, never by the UI.
const _parentUid = 'parent_uid';
const _childId = 'child_id';

/// Shared plumbing: a typed query stream scoped to one parent.
class _Base {
  const _Base(this.db, this.parentUid);

  final FirebaseFirestore db;
  final String parentUid;

  Query<Map<String, dynamic>> scoped(String collection) =>
      db.collection(collection).where(_parentUid, isEqualTo: parentUid);
}

class FirestoreChildRepository extends _Base implements ChildRepository {
  const FirestoreChildRepository(super.db, super.parentUid);

  @override
  Stream<List<Child>> watchChildren(String parentUid) {
    return scoped(Collections.children)
        .orderBy('birth_date')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Child.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  @override
  Future<Child> add({
    required String parentUid,
    required String name,
    required DateTime birthDate,
    required Gender gender,
  }) async {
    final doc = db.collection(Collections.children).doc();
    final child = Child(
      id: doc.id,
      parentUid: parentUid,
      name: name,
      birthDate: birthDate,
      gender: gender,
    );
    await doc.set(child.toMap());
    return child;
  }

  @override
  Future<void> update(Child child) =>
      db.collection(Collections.children).doc(child.id).update(child.toMap());

  @override
  Future<void> delete(String childId) async {
    // Firestore does not cascade. Batching keeps the cleanup atomic so a
    // half-deleted child cannot linger.
    final batch = db.batch();
    for (final collection in [
      Collections.logs,
      Collections.records,
      Collections.reminders,
    ]) {
      final owned = await scoped(collection)
          .where(_childId, isEqualTo: childId)
          .get();
      for (final doc in owned.docs) {
        batch.delete(doc.reference);
      }
    }
    batch.delete(db.collection(Collections.children).doc(childId));
    await batch.commit();
  }
}

class FirestoreLogRepository extends _Base
    implements DevelopmentLogRepository {
  const FirestoreLogRepository(super.db, super.parentUid);

  @override
  Stream<List<DevelopmentLog>> watchLogs(String childId) {
    return scoped(Collections.logs)
        .where(_childId, isEqualTo: childId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => DevelopmentLog.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  @override
  Future<DevelopmentLog> add(DevelopmentLog log) async {
    final doc = db.collection(Collections.logs).doc();
    await doc.set({...log.toMap(), _parentUid: parentUid});
    return log.copyWithId(doc.id);
  }

  @override
  Future<void> update(DevelopmentLog log) => db
      .collection(Collections.logs)
      .doc(log.id)
      .update({...log.toMap(), _parentUid: parentUid});

  @override
  Future<void> delete(String logId) =>
      db.collection(Collections.logs).doc(logId).delete();
}

class FirestoreMedicalRecordRepository extends _Base
    implements MedicalRecordRepository {
  const FirestoreMedicalRecordRepository(super.db, super.parentUid);

  @override
  Stream<List<MedicalRecord>> watchRecords(String childId) {
    return scoped(Collections.records)
        .where(_childId, isEqualTo: childId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => MedicalRecord.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  @override
  Future<MedicalRecord> add(MedicalRecord record) async {
    final doc = db.collection(Collections.records).doc();
    await doc.set({...record.toMap(), _parentUid: parentUid});
    return record.copyWithId(doc.id);
  }

  @override
  Future<void> delete(String recordId) =>
      db.collection(Collections.records).doc(recordId).delete();
}

class FirestoreReminderRepository extends _Base
    implements ReminderRepository {
  const FirestoreReminderRepository(super.db, super.parentUid);

  @override
  Stream<List<Reminder>> watchReminders(String childId) {
    return scoped(Collections.reminders)
        .where(_childId, isEqualTo: childId)
        .orderBy('scheduled_time')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Reminder.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  @override
  Future<Reminder> add(Reminder reminder) async {
    final doc = db.collection(Collections.reminders).doc();
    await doc.set({...reminder.toMap(), _parentUid: parentUid});
    return reminder.copyWithId(doc.id);
  }

  /// Writes a whole vaccination plan in one batch — 26 doses would otherwise
  /// be 26 round trips.
  Future<void> addAll(Iterable<Reminder> reminders) async {
    final batch = db.batch();
    for (final r in reminders) {
      batch.set(db.collection(Collections.reminders).doc(), {
        ...r.toMap(),
        _parentUid: parentUid,
      });
    }
    await batch.commit();
  }

  @override
  Future<void> update(Reminder reminder) => db
      .collection(Collections.reminders)
      .doc(reminder.id)
      .update({...reminder.toMap(), _parentUid: parentUid});

  @override
  Future<void> delete(String reminderId) =>
      db.collection(Collections.reminders).doc(reminderId).delete();
}
