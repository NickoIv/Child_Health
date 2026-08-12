/// A phone number, in the one shape WhatsApp accepts.
///
/// GREEN-API addresses a chat as `77001234567@c.us` — digits only, country
/// code first, no plus and no separators. What a parent types is none of
/// those things: «+7 700 123-45-67», «8 (700) 1234567», a number copied out of
/// a contact card with a non-breaking space in it. All of them mean the same
/// person, so all of them are accepted and normalised here rather than
/// refused with a format rule nobody reads.
library;

/// Digits only, with the leading 8 that Russian and Kazakh numbers are
/// written with turned into the 7 the international format needs.
///
/// Returns an empty string when there is nothing usable, which is also how
/// "she left the field alone" arrives — the phone is optional.
String normalizePhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';

  // 8 700 123 45 67 — the domestic way of writing the same number.
  if (digits.length == 11 && digits.startsWith('8')) {
    return '7${digits.substring(1)}';
  }
  // 700 123 45 67 — typed without the country code at all.
  if (digits.length == 10) return '7$digits';
  return digits;
}

/// Whether this could be dialled.
///
/// Deliberately loose: ten to fifteen digits covers every country's numbering
/// plan, and an app that knows better than a parent about her own husband's
/// number is an app that refuses to send the invitation.
bool looksLikePhone(String raw) {
  final digits = normalizePhone(raw);
  return digits.length >= 10 && digits.length <= 15;
}

/// The invitation as a WhatsApp chat that is already open and already typed.
///
/// This is the delivery that cannot fail. The Worker's own send needs an API
/// account that has to stay authorised, and a letter needs a mail provider
/// this build does not have — both of them can quietly deliver nothing. A
/// `wa.me` link needs neither: it opens WhatsApp on her own phone with the
/// message written out, and she presses send. If it went nowhere she can see
/// that it went nowhere, which is the part that was missing.
///
/// [phone] may be empty — then it opens WhatsApp with the text and no
/// recipient, and she picks the chat herself.
String whatsAppLink({required String phone, required String message}) {
  final digits = normalizePhone(phone);
  // `encodeComponent` rather than `encodeQueryComponent`: the latter writes a
  // space as `+`, which is only a space to a reader who knows the string is a
  // query parameter. WhatsApp shows the message to a person.
  final text = Uri.encodeComponent(message);
  return digits.isEmpty
      ? 'https://wa.me/?text=$text'
      : 'https://wa.me/$digits?text=$text';
}
