/// Handing a link to the browser, in a new tab.
///
/// Separate from `core/feedback/open_mail.dart` on purpose, and the difference
/// is the target rather than the code: a `mailto:` has to replace the current
/// document or an iOS home-screen app is left on a blank page with no back
/// button, while a link to WhatsApp must *not* — navigating away from the diary
/// to send an invitation would close the diary.
library;

export 'open_url_stub.dart' if (dart.library.js_interop) 'open_url_web.dart';
