import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../ai/ai_config.dart';

/// Sending the invitation as a letter.
///
/// The invitation itself is a Firestore document and always has been — that is
/// what grants the access. The letter is only how the other person finds out
/// it exists, which until now was nobody's job: the app said «отправлено» and
/// sent nothing, and a father waited at an inbox that was never going to have
/// anything in it.
///
/// It goes through the same Cloudflare Worker the assistant uses, for the same
/// reason: the mail provider's key must not be in a web bundle, where it is
/// public. The Worker checks that the caller really owns the invitation before
/// it sends anything, so the endpoint cannot be used as a relay.

/// Where this copy of the app is served from — the address the letter and
/// the copied message point at.
///
/// `Uri.base.origin` alone is not safe to call: off the web `Uri.base` is a
/// `file://` path and `origin` throws for any scheme that is not http. It
/// threw in the widget tests, and the invitation reported a failure it had
/// not had.
String appLink() {
  final base = Uri.base;
  if (base.scheme == 'https' || base.scheme == 'http') return base.origin;
  return 'https://child-health-tracker-7aad1.web.app';
}

/// What happened, in terms the screen can say out loud.
enum InviteMailResult {
  /// The letter is on its way.
  sent,

  /// This build has no Worker configured, so there is nowhere to send from.
  notConfigured,

  /// The Worker is there but has no mail key, or the provider refused.
  failed,
}

/// Asks the Worker to write to [email].
///
/// Never throws. A letter that does not go out must not take the invitation
/// with it — the access has already been granted, and the screen falls back to
/// «скопируйте и передайте сами», which always works.
Future<InviteMailResult> sendInviteMail({
  required String idToken,
  required String childId,
  required String childName,
  required String email,
  required String link,
  required String fromName,
  http.Client? client,
}) async {
  if (!AiConfig.isConfigured || idToken.isEmpty) {
    return InviteMailResult.notConfigured;
  }

  final http.Client c = client ?? http.Client();
  try {
    final response = await c
        .post(
          Uri.parse('${AiConfig.proxyUrl}/invite'),
          headers: {
            'Content-Type': 'application/json',
            // Proof of who is asking. The Worker trades it for a uid and
            // compares that against the invitation's owner.
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'child_id': childId,
            'child_name': childName,
            'email': email,
            'link': link,
            'from_name': fromName,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) return InviteMailResult.sent;
    // 501 is the Worker saying it has no mail key configured, which is a
    // different thing from a refusal and worth a different sentence.
    if (response.statusCode == 501) return InviteMailResult.notConfigured;
    return InviteMailResult.failed;
  } catch (_) {
    return InviteMailResult.failed;
  } finally {
    if (client == null) c.close();
  }
}
