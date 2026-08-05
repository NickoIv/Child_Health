import '../models/family_member.dart';
import 'memory_repository.dart';

/// Who else can see this child.
///
/// Two questions, from opposite ends: the mother asks "who have I invited",
/// the father asks "has anyone invited me". They are different queries against
/// the same documents, and keeping both on one interface is what stops the
/// second from being bolted on later as a special case.
abstract class FamilyRepository {
  /// Everyone on one child, owner included, oldest invitation first.
  Stream<List<FamilyMember>> watchMembers(String childId);

  /// Invitations addressed to [email], across every child.
  ///
  /// This is the one query in the app that deliberately crosses the ownership
  /// boundary, and it is safe because the address is the caller's own — the
  /// security rule compares it against the signed-in token, not against
  /// anything the client sends.
  Stream<List<FamilyMember>> watchInvitationsFor(String email);

  /// Writes a pending invitation. Re-inviting the same address overwrites the
  /// previous invitation rather than making a second one.
  Future<FamilyMember> invite({
    required String childId,
    required String ownerUid,
    required String email,
  });

  /// Marks an invitation accepted and records which account took it.
  Future<void> accept(FamilyMember invitation, String viewerUid);

  /// Withdraws access. The owner's own membership is never removable — a
  /// record with nobody who can write to it is a record nobody can correct.
  Future<void> revoke({required String childId, required String email});

  /// Records that the viewer said thank you on [day].
  ///
  /// A date written onto the membership document that already exists. There is
  /// no message to carry and nowhere for one to go: the only thing being sent
  /// is that today was noticed. Sending twice on the same day writes the same
  /// date again and changes nothing.
  Future<void> thank({
    required String childId,
    required String email,
    required DateTime day,
  });
}

/// A family that lives in memory, for the demo stack and the tests.
///
/// One flat list rather than a map per child: there are never more than a
/// handful of these, and the [Store] the rest of the demo stack is built on
/// already does the republish-on-change that both queries need.
class MemoryFamilyRepository implements FamilyRepository {
  final _store = Store<FamilyMember>(
    <FamilyMember>[],
    (a, b) => a.invitedAt.compareTo(b.invitedAt),
  );

  @override
  Stream<List<FamilyMember>> watchMembers(String childId) =>
      _store.watch((m) => m.childId == childId);

  @override
  Stream<List<FamilyMember>> watchInvitationsFor(String email) {
    final wanted = normalizeEmail(email);
    if (wanted.isEmpty) return Stream.value(const []);
    return _store.watch((m) => m.email == wanted);
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
    _store.mutate((list) {
      list.removeWhere(
        (m) => m.childId == childId && m.email == member.email,
      );
      list.add(member);
    });
    return member;
  }

  @override
  Future<void> accept(FamilyMember invitation, String viewerUid) async {
    _store.mutate((list) {
      final at = list.indexWhere(
        (m) => m.childId == invitation.childId && m.email == invitation.email,
      );
      if (at == -1) return;
      list[at] = list[at].accept(viewerUid, DateTime.now());
    });
  }

  @override
  Future<void> revoke({
    required String childId,
    required String email,
  }) async {
    final wanted = normalizeEmail(email);
    _store.mutate(
      (list) => list.removeWhere(
        // The owner is not removable: a record nobody can write to is a
        // record nobody can correct.
        (m) =>
            m.childId == childId &&
            m.email == wanted &&
            m.role != FamilyRole.owner,
      ),
    );
  }

  @override
  Future<void> thank({
    required String childId,
    required String email,
    required DateTime day,
  }) async {
    final wanted = normalizeEmail(email);
    _store.mutate((list) {
      final at = list.indexWhere(
        (m) => m.childId == childId && m.email == wanted,
      );
      if (at == -1) return;
      list[at] = list[at].thank(day);
    });
  }

  void dispose() => _store.dispose();
}
