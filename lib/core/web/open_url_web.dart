import 'package:web/web.dart' as web;

/// Opens [url] in a new tab.
///
/// False when the browser refused — which in practice means a popup blocker,
/// and only ever happens when the call has drifted away from the tap that
/// asked for it. The screen that calls this keeps a "copy" button beside the
/// one that opens the link, so a refusal is an inconvenience rather than a
/// dead end.
Future<bool> openUrl(String url) async {
  try {
    return web.window.open(url, '_blank') != null;
  } catch (_) {
    return false;
  }
}
