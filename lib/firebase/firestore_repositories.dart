import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/photos/compression.dart';
import '../data/family_repository.dart';
import '../data/photo_repository.dart';
import '../data/repositories.dart';
import '../data/user_repository.dart';
import '../models/app_user.dart';
import '../models/child.dart';
import '../models/development_log.dart';
import '../models/family_member.dart';
import '../models/invite_code.dart';
import '../models/medical_record.dart';
import '../models/photo.dart';
import '../models/reminder.dart';

/// Collection names, matching section 4 of the specification.
abstract final class Collections {
  static const users = 'users';
  static const children = 'children';
  static const logs = 'development_logs';
  static const records = 'medical_records';
  static const reminders = 'reminders';
  static const photos = 'photos';

  /// Subcollection of `children`. Who else may look at this child.
  static const familyMembers = 'family_members';

  /// One document per (owner, viewer) pair, id `{ownerUid}_{viewerUid}`.
  ///
  /// Redundant with the invitation it is created from, and worth it: without
  /// it every rule protecting a log, a photo or a reminder would have to walk
  /// back to the child's subcollection to find out whether the reader is
  /// family. This is a single existence check on a known path instead.
  static const familyAccess = 'family_access';

  /// One document per invitation link, id = the code itself.
  ///
  /// Top level rather than under the child, because whoever opens the link
  /// does not yet know which child it is for — that is what the document
  /// tells them. Readable by `get` and never by `list`: knowing the code is
  /// the whole of the authorisation, so being able to enumerate them would be
  /// being able to invite yourself.
  static const inviteCodes = 'invite_codes';
}

/// Id of the grant that lets [viewerUid] read what [ownerUid] wrote.
String familyAccessId(String ownerUid, String viewerUid) =>
    '${ownerUid}_$viewerUid';

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
    // Sorted in Dart rather than with orderBy on purpose. A parent has a
    // handful of children, so the cost is nil — and this is the very first
    // query a new account runs. Ordering server-side would make it need a
    // composite index, and the app would greet every new user with an error
    // for the minutes that index spends building.
    return scoped(Collections.children).snapshots().map((snap) {
      final children = snap.docs
          .map((d) => Child.fromMap(d.id, d.data()))
          .toList();
      children.sort((a, b) => a.birthDate.compareTo(b.birthDate));
      return children;
    });
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
  Future<void> update(MedicalRecord record) => db
      .collection(Collections.records)
      .doc(record.id)
      .update({...record.toMap(), _parentUid: parentUid});

  @override
  Future<void> delete(String recordId) =>
      db.collection(Collections.records).doc(recordId).delete();
}

/// The parent's profile document, keyed by uid.
///
/// No `parent_uid` field here: the document id *is* the uid, which is what
/// the security rule compares against.
class FirestoreUserRepository implements UserRepository {
  const FirestoreUserRepository(this.db);

  final FirebaseFirestore db;

  @override
  Stream<AppUser?> watchProfile(String uid) {
    return db
        .collection(Collections.users)
        .doc(uid)
        .snapshots()
        .map((snap) {
          final data = snap.data();
          return data == null ? null : AppUser.fromMap(snap.id, data);
        });
  }

  @override
  Future<void> save(AppUser user) => db
      .collection(Collections.users)
      .doc(user.uid)
      .set(user.toMap(), SetOptions(merge: true));

  @override
  Future<void> delete(String uid) =>
      db.collection(Collections.users).doc(uid).delete();
}

/// Who else can see a child, and who has invited whom.
class FirestoreFamilyRepository implements FamilyRepository {
  const FirestoreFamilyRepository(this.db);

  final FirebaseFirestore db;

  CollectionReference<Map<String, dynamic>> _members(String childId) => db
      .collection(Collections.children)
      .doc(childId)
      .collection(Collections.familyMembers);

  @override
  Stream<List<FamilyMember>> watchMembers(String childId) {
    return _members(childId).snapshots().map((snap) {
      final members = snap.docs
          .map((d) => FamilyMember.fromMap(d.id, d.data()))
          .toList();
      members.sort((a, b) => a.invitedAt.compareTo(b.invitedAt));
      return members;
    });
  }

  @override
  Stream<List<FamilyMember>> watchInvitationsFor(String email) {
    final wanted = normalizeEmail(email);
    if (wanted.isEmpty) return Stream.value(const []);

    // The one query in the app that reaches across owners. It is safe because
    // the rule compares the document's address against the caller's verified
    // token, not against this filter — a client that widened the filter would
    // simply be refused.
    return db
        .collectionGroup(Collections.familyMembers)
        .where('email', isEqualTo: wanted)
        .snapshots()
        .map((snap) {
          final invitations = snap.docs
              .map((d) => FamilyMember.fromMap(d.id, d.data()))
              .toList();
          invitations.sort((a, b) => a.invitedAt.compareTo(b.invitedAt));
          return invitations;
        });
  }

  @override
  Future<FamilyMember> invite({
    required String childId,
    required String ownerUid,
    required String email,
  }) async {
    final member = FamilyMember(
      email: normalizeEmail(email),
      childId: childId,
      ownerUid: ownerUid,
      role: FamilyRole.viewer,
      status: InviteStatus.pending,
      invitedAt: DateTime.now(),
    );
    // Keyed by the address, so re-inviting replaces rather than duplicates.
    await _members(childId).doc(member.email).set(member.toMap());
    return member;
  }

  @override
  Future<void> accept(FamilyMember invitation, String viewerUid) async {
    final accepted = invitation.accept(viewerUid, DateTime.now());
    // Two writes, in this order. The invitation is the proof the grant is
    // allowed to exist, so it has to be accepted first; a grant written
    // against a pending invitation is refused by the rules.
    await _members(invitation.childId).doc(invitation.email).update({
      'status': accepted.status.code,
      'accepted_at': accepted.acceptedAt?.toIso8601String(),
      'viewer_uid': viewerUid,
    });
    await db
        .collection(Collections.familyAccess)
        .doc(familyAccessId(invitation.ownerUid, viewerUid))
        .set({
          'owner_uid': invitation.ownerUid,
          'viewer_uid': viewerUid,
          'child_id': invitation.childId,
          'email': invitation.email,
          'granted_at': DateTime.now().toIso8601String(),
        });
  }

  @override
  Future<void> revoke({
    required String childId,
    required String email,
  }) async {
    final wanted = normalizeEmail(email);
    final doc = await _members(childId).doc(wanted).get();
    final data = doc.data();
    if (data == null) return;

    final member = FamilyMember.fromMap(doc.id, data);
    // The owner is not removable. A record with nobody who can write to it is
    // a record nobody can correct.
    if (member.role == FamilyRole.owner) return;

    await doc.reference.delete();
    if (member.viewerUid.isNotEmpty) {
      await db
          .collection(Collections.familyAccess)
          .doc(familyAccessId(member.ownerUid, member.viewerUid))
          .delete();
    }
  }

  @override
  Future<void> thank({
    required String childId,
    required String email,
    required DateTime day,
  }) async {
    // One field on a document that already exists. No new collection, and
    // nothing here the existing rule does not already allow the viewer to
    // write: the address, the role, the owner and the child are untouched.
    await _members(childId).doc(normalizeEmail(email)).update({
      'thanked_on': dayStamp(day),
    });
  }

  CollectionReference<Map<String, dynamic>> get _codes =>
      db.collection(Collections.inviteCodes);

  @override
  Future<InviteCode> createCode({
    required String childId,
    required String ownerUid,
    required DateTime now,
  }) async {
    final code = InviteCode(
      code: newInviteCode(),
      childId: childId,
      ownerUid: ownerUid,
      createdAt: now,
      expiresAt: now.add(inviteCodeLifetime),
    );
    await _codes.doc(code.code).set(code.toMap());
    return code;
  }

  @override
  Future<InviteCode?> codeById(String code) async {
    final doc = await _codes.doc(code).get();
    final data = doc.data();
    return data == null ? null : InviteCode.fromMap(doc.id, data);
  }

  @override
  Future<FamilyMember> claimCode({
    required String code,
    required String viewerUid,
    required String viewerEmail,
    required DateTime now,
  }) async {
    final invitation = await codeById(code);
    if (invitation == null || !invitation.isUsableAt(now)) {
      throw StateError('invite code is not usable');
    }
    final email = normalizeEmail(viewerEmail);

    // Three writes, in this order, and the order is the security.
    //
    // The code is spent first: the rule on the membership below looks the code
    // up and requires it to name this caller, so nothing can be written until
    // this has succeeded, and this can only succeed once. Then the membership,
    // which is what the grant is checked against. Then the grant itself, which
    // is what every other rule in the file reads.
    await _codes.doc(code).update({
      'claimed_by': viewerUid,
      'claimed_email': email,
    });

    final member = FamilyMember(
      email: email,
      childId: invitation.childId,
      ownerUid: invitation.ownerUid,
      role: FamilyRole.viewer,
      status: InviteStatus.accepted,
      invitedAt: invitation.createdAt,
      acceptedAt: now,
      viewerUid: viewerUid,
    );
    await _members(invitation.childId).doc(email).set({
      ...member.toMap(),
      // Which link authorised this. The rule reads it to find the code
      // document; it is not a secret to anyone who can already see this.
      'via_code': code,
    });

    await db
        .collection(Collections.familyAccess)
        .doc(familyAccessId(invitation.ownerUid, viewerUid))
        .set({
          'owner_uid': invitation.ownerUid,
          'viewer_uid': viewerUid,
          'child_id': invitation.childId,
          'email': email,
          'granted_at': now.toIso8601String(),
        });

    return member;
  }
}

class FirestorePhotoRepository extends _Base implements PhotoRepository {
  const FirestorePhotoRepository(super.db, super.parentUid);

  @override
  Future<Photo> upload({
    required String childId,
    required Uint8List bytes,
    String caption = '',
  }) async {
    // Compression happens before the write, not after: an image that will not
    // fit must fail here with an explanation, rather than as a rejected
    // document the user cannot interpret.
    final prepared = preparePhoto(bytes);
    final doc = db.collection(Collections.photos).doc();
    final photo = Photo(
      id: doc.id,
      childId: childId,
      base64Data: prepared.base64Data,
      width: prepared.width,
      height: prepared.height,
      createdAt: DateTime.now(),
      caption: caption,
    );
    await doc.set({...photo.toMap(), _parentUid: parentUid});
    return photo;
  }

  @override
  Future<Photo?> byId(String photoId) async {
    final snap = await db.collection(Collections.photos).doc(photoId).get();
    final data = snap.data();
    if (data == null) return null;
    return Photo.fromMap(snap.id, data);
  }

  @override
  Future<void> delete(String photoId) =>
      db.collection(Collections.photos).doc(photoId).delete();
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
