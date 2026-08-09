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
