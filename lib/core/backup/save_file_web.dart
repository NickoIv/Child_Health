import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Writes [text] out as a download.
///
/// A blob and an anchor rather than a package: this is one dialog on one
/// platform, and every plugin that wraps it drags in native code for three
/// this build does not target.
///
/// The object URL is revoked afterwards. It holds the whole file in memory
/// until it is, and a diary of two years is not nothing.
Future<bool> saveTextFile(String filename, String text) async {
  String? url;
  try {
    final blob = web.Blob(
      [text.toJS].toJS,
      web.BlobPropertyBag(type: 'application/json;charset=utf-8'),
    );
    url = web.URL.createObjectURL(blob);

    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = filename
      ..style.display = 'none';

    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();
    return true;
  } catch (_) {
    return false;
  } finally {
    if (url != null) web.URL.revokeObjectURL(url);
  }
}
