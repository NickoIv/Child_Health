/// One text file, chosen by the parent.
///
/// The browser is the only place this app runs today, and the browser's own
/// file dialog is the only picker that needs no package and no permission.
/// The native side is a stub for now — nothing calls it, and a plugin added
/// for a platform nobody builds would be a dependency paying rent for
/// nothing.
library;

export 'pick_file_stub.dart' if (dart.library.js_interop) 'pick_file_web.dart';
