/// Handing a finished file to the browser.
///
/// Same shape as `pick_file.dart` — one line of browser API on the web, a stub
/// everywhere else, and no plugin for platforms this build does not target.
library;

export 'save_file_stub.dart' if (dart.library.js_interop) 'save_file_web.dart';
