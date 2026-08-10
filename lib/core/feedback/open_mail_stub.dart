/// No mail client to hand off to outside the browser yet — see
/// `open_mail.dart`.
///
/// Returns false rather than throwing, so the screen falls back to showing
/// the address for copying instead of crashing on a button press.
Future<bool> openMail(String url) async => false;
