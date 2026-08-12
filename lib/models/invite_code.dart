import 'dart:math';

import 'json.dart';

/// An invitation that is a link rather than an address.
///
/// «Может проще убрать почту и оставить ватсап, чтобы у пользователей не было
/// трудностей.» Removing the address field alone could not work: access is
/// granted to the account somebody signs in with, and an account *is* an email
/// — a phone number has nobody to grant anything to. So the address is still
/// what the grant is made to; it is simply no longer typed by anyone. She
/// creates a link, sends it in WhatsApp, he opens it and signs in, and the app
/// reads his address off his own token.
///
/// The code is a bearer credential: whoever holds the link can take the
/// invitation. That is the same bargain every share link makes, and it is
/// bounded here — one use, and [lifetime] to use it in.
class InviteCode {
  const InviteCode({
    required this.code,
    required this.childId,
    required this.ownerUid,
    required this.createdAt,
    required this.expiresAt,
    this.claimedBy = '',
    this.claimedEmail = '',
  });

  /// The document id, and the only secret involved.
  final String code;
  final String childId;
  final String ownerUid;
  final DateTime createdAt;
  final DateTime expiresAt;

  /// The account that took it, or empty. Set once and never cleared: a link
  /// that has been used is spent, so a message forwarded on afterwards opens
  /// nothing.
  final String claimedBy;
  final String claimedEmail;

  bool get isClaimed => claimedBy.isNotEmpty;

  bool isUsableAt(DateTime now) => !isClaimed && now.isBefore(expiresAt);

  InviteCode claim(String uid, String email) => InviteCode(
    code: code,
    childId: childId,
    ownerUid: ownerUid,
    createdAt: createdAt,
    expiresAt: expiresAt,
    claimedBy: uid,
    claimedEmail: email,
  );

  /// Stored as milliseconds, not as text: the security rule compares the
  /// expiry against `request.time`, and a rule cannot parse an ISO string.
  Map<String, dynamic> toMap() => {
    'child_id': childId,
    'owner_uid': ownerUid,
    'created_at': createdAt.toIso8601String(),
    'expires_at_ms': expiresAt.millisecondsSinceEpoch,
    'claimed_by': claimedBy,
    'claimed_email': claimedEmail,
  };

  factory InviteCode.fromMap(String id, Map<String, dynamic> map) {
    return InviteCode(
      code: id,
      childId: map['child_id'] as String? ?? '',
      ownerUid: map['owner_uid'] as String? ?? '',
      createdAt: parseDate(map['created_at']) ?? DateTime.now(),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        (map['expires_at_ms'] as num?)?.toInt() ?? 0,
      ),
      claimedBy: map['claimed_by'] as String? ?? '',
      claimedEmail: map['claimed_email'] as String? ?? '',
    );
  }
}

/// How long a link is worth sending.
///
/// A week rather than an hour: it is sent to a husband who reads WhatsApp in
/// the evening, and an invitation that expires while he is at work is an
/// invitation she has to make twice. A week rather than for ever: a link in a
/// chat history is a key lying on a table.
const inviteCodeLifetime = Duration(days: 7);

/// The alphabet a code is drawn from.
///
/// No `i`, `l`, `o` or `0`/`1`: the link is normally tapped, but it is
/// sometimes read aloud down a telephone, and those four are the ones that
/// come back wrong when it is.
const _alphabet = 'abcdefghjkmnpqrstuvwxyz23456789';

/// Sixteen characters out of `Random.secure()` — about eighty bits, which is
/// not guessable at any rate Firestore would answer.
String newInviteCode([Random? random]) {
  final rng = random ?? Random.secure();
  return String.fromCharCodes(
    List.generate(16, (_) => _alphabet.codeUnitAt(rng.nextInt(_alphabet.length))),
  );
}
