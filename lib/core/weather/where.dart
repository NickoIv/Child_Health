/// Where the phone is, if she lets it say.
///
/// Same shape as `pick_file.dart`: the browser's own API on the web, a stub
/// everywhere else, and no plugin pulled in for platforms this build does not
/// target.
///
/// Asked for only when a question is about going outside — see
/// [asksAboutWeather] — so a parent who never asks is never prompted.
library;

export 'where_stub.dart' if (dart.library.js_interop) 'where_web.dart';
