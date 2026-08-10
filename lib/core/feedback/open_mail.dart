/// Opening her own mail client on a `mailto:` link.
///
/// The same shape as `pick_file.dart`: one line of browser API on the web, a
/// stub everywhere else, and no plugin dragged in for three platforms this
/// build does not target.
///
/// Nothing is sent by the app. `mailto:` hands the message to whatever she
/// already uses and stops there — she sees the letter, edits it and presses
/// send herself, and if she changes her mind nothing has left the phone.
library;

export 'open_mail_stub.dart' if (dart.library.js_interop) 'open_mail_web.dart';
