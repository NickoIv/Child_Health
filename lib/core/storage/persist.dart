/// Asking the browser to keep what it is holding.
///
/// Same shape as `pick_file.dart`: the browser's own API on the web, a stub
/// everywhere else.
library;

export 'persist_stub.dart' if (dart.library.js_interop) 'persist_web.dart';
