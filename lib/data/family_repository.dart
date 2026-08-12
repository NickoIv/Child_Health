import '../models/family_member.dart';
import '../models/invite_code.dart';
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

  /// Mints a link nobody has to type an address into. See [InviteCode].
  Future<InviteCode> createCode({
    required String childId,
    required String ownerUid,
    required DateTime now,
  });

  /// The invitation behind a link, or null if there is no such code.
  ///
  /// Readable by anyone signed in who knows the code — that is what a link
  /// invitation is. Enumerating them is not possible: the rule allows `get`
  /// and denies `list`.
  Future<InviteCode?> codeById(String code);

  /// Takes the invitation, and writes the membership it authorises.
  ///
  /// Returns the membership so the caller can act on it without a second
  /// round trip. Throws [StateError] if the link is spent or expired — a
  /// forwarded message must not let a third person in.
  Future<FamilyMember> claimCode({
    required String code,
    required String viewerUid,
    required String viewerEmail,
    required DateTime now,
  });

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

  /// Codes live beside the memberships rather than in a [Store]: nothing
  /// watches them, they are read once each by whoever was sent the link.
  final _codes = <String, InviteCode>{};

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
    _codes[code.code] = code;
    return code;
  }

  @override
  Future<InviteCode?> codeById(String code) async => _codes[code];

  @override
  Future<FamilyMember> claimCode({
    required String code,
    required String viewerUid,
    required String viewerEmail,
    required DateTime now,
  }) async {
    final invitation = _codes[code];
    if (invitation == null || !invitation.isUsableAt(now)) {
      throw StateError('invite code is not usable');
    }
    final email = normalizeEmail(viewerEmail);
    _codes[code] = invitation.claim(viewerUid, email);

    final member = FamilyMember(
      email: email,
      childId: invitation.childId,
      ownerUid: invitation.ownerUid,
      role: FamilyRole.viewer,
      // Accepted, because claiming is the acceptance: the screen that leads
      // here has already said what the invitation gives and which account it
      // will be attached to, and pressing the button was the answer.
      status: InviteStatus.accepted,
      invitedAt: invitation.createdAt,
      acceptedAt: now,
      viewerUid: viewerUid,
    );
    _store.mutate((list) {
      list.removeWhere(
        (m) => m.childId == member.childId && m.email == member.email,
      );
      list.add(member);
    });
    return member;
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
