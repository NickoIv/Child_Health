/// No browser to hand a link to — see `open_url.dart`.
///
/// False rather than a throw, so a widget test that presses the button gets
/// the same fallback a refused popup gets instead of a crash.
Future<bool> openUrl(String url) async => false;
