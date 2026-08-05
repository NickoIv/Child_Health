import 'json.dart';

/// What a person is allowed to do with a child's record.
///
/// Two roles and no scale between them, because the question a mother is
/// actually asking is binary: can he see it, or can he change it. A role
/// system with five tiers would be five decisions she does not want to make
/// about her own family.
enum FamilyRole {
  owner('owner'),
  viewer('viewer');

  const FamilyRole(this.code);

  final String code;

  static FamilyRole fromCode(String? code) => FamilyRole.values.firstWhere(
    (r) => r.code == code,
    orElse: () => FamilyRole.viewer,
  );
}

enum InviteStatus {
  pending('pending'),
  accepted('accepted');

  const InviteStatus(this.code);

  final String code;

  static InviteStatus fromCode(String? code) => InviteStatus.values.firstWhere(
    (s) => s.code == code,
    orElse: () => InviteStatus.pending,
  );
}

/// A person with access to one child's record.
///
/// Lives at `children/{childId}/family_members/{email}` — keyed by the invited
/// address rather than by a generated id, because at the moment the invitation
/// is written the invited person may not have an account at all, and the
/// address is the only thing that identifies them. It is also what lets a
/// security rule find the invitation from `request.auth.token.email` without
/// the client passing anything it could lie about.
///
/// [ownerUid] and [childId] are denormalised onto the document so that the
/// person accepting can act on the invitation knowing only the invitation.
class FamilyMember {
  const FamilyMember({
    required this.email,
    required this.childId,
    required this.ownerUid,
    required this.role,
    required this.status,
    required this.invitedAt,
    this.acceptedAt,
    this.viewerUid = '',
    this.thankedOn = '',
  });

  /// Lowercased. Addresses are compared, never displayed back as typed.
  final String email;
  final String childId;
  final String ownerUid;
  final FamilyRole role;
  final InviteStatus status;
  final DateTime invitedAt;
  final DateTime? acceptedAt;

  /// Filled in when the invitation is accepted, and only then: before that
  /// nobody knows which account the address will turn out to belong to.
  final String viewerUid;

  /// The last day this person said thank you, as `yyyy-MM-dd`, or empty.
  ///
  /// A date and nothing else. Not a message, not a count, not a history — the
  /// whole of what one parent may send the other is that today was noticed,
  /// and a field that could hold more would eventually be asked to.
  ///
  /// It lives on the membership document because that document already exists,
  /// already says who these two people are to each other, and is already
  /// readable by exactly the two of them.
  final String thankedOn;

  bool get isPending => status == InviteStatus.pending;
  bool get isAccepted => status == InviteStatus.accepted;

  FamilyMember accept(String uid, DateTime at) => FamilyMember(
    email: email,
    childId: childId,
    ownerUid: ownerUid,
    role: role,
    status: InviteStatus.accepted,
    invitedAt: invitedAt,
    acceptedAt: at,
    viewerUid: uid,
    thankedOn: thankedOn,
  );

  FamilyMember thank(DateTime day) => FamilyMember(
    email: email,
    childId: childId,
    ownerUid: ownerUid,
    role: role,
    status: status,
    invitedAt: invitedAt,
    acceptedAt: acceptedAt,
    viewerUid: viewerUid,
    thankedOn: dayStamp(day),
  );

  /// Whether today has already been thanked for. One a day, and the date on
  /// the document is what says so — not a flag on the sender's phone, which a
  /// second phone would know nothing about.
  bool thankedOnDay(DateTime day) => thankedOn == dayStamp(day);

  Map<String, dynamic> toMap() => {
    'email': email,
    'child_id': childId,
    'owner_uid': ownerUid,
    'role': role.code,
    'status': status.code,
    'invited_at': invitedAt.toIso8601String(),
    'accepted_at': acceptedAt?.toIso8601String(),
    'viewer_uid': viewerUid,
    'thanked_on': thankedOn,
  };

  factory FamilyMember.fromMap(String id, Map<String, dynamic> map) {
    return FamilyMember(
      // The document id is the address; the field is a copy for the rule to
      // compare against, and the id wins if they ever disagree.
      email: (map['email'] as String? ?? id).toLowerCase(),
      childId: map['child_id'] as String? ?? '',
      ownerUid: map['owner_uid'] as String? ?? '',
      role: FamilyRole.fromCode(map['role'] as String?),
      status: InviteStatus.fromCode(map['status'] as String?),
      invitedAt: parseDate(map['invited_at']) ?? DateTime.now(),
      acceptedAt: parseDate(map['accepted_at']),
      viewerUid: map['viewer_uid'] as String? ?? '',
      thankedOn: map['thanked_on'] as String? ?? '',
    );
  }
}

/// `2026-08-05` — a calendar day, with no clock and no zone on it.
///
/// A day rather than an instant on purpose: "today" is the only granularity
/// this feature has, and a timestamp would invite somebody to display the
/// minute at which one parent thanked the other.
String dayStamp(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// Addresses are matched, so they are normalised in exactly one place.
String normalizeEmail(String raw) => raw.trim().toLowerCase();

/// Enough of an address to be worth sending to. Deliberately loose: the point
/// is to catch a typed-in mistake, not to adjudicate RFC 5322.
bool looksLikeEmail(String raw) {
  final email = normalizeEmail(raw);
  return RegExp(r'^[^@\s]+@[^@\s.]+\.[^@\s]+$').hasMatch(email);
}
