import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// What came back: the name, so the screen can say which file, and the text.
typedef PickedFile = ({String name, String text});

/// Opens the browser's own file dialog and reads what comes back as text.
///
/// A hidden `<input type="file">` rather than a package: this is one dialog
/// on one platform, and every plugin that wraps it drags in native code for
/// three platforms this build does not target.
///
/// Read as UTF-8 with a fallback to Windows-1251, because that is what these
/// files are. An export written by a Russian Android app and opened once in
/// Excel comes back in the ANSI codepage, and a diary of mojibake is worse
/// than a refusal.
Future<PickedFile?> pickTextFile() async {
  final input = web.document.createElement('input') as web.HTMLInputElement;
  input.type = 'file';
  input.accept = '.csv,.txt,.tsv,text/csv,text/plain';
  input.style.display = 'none';
  web.document.body?.appendChild(input);

  final completer = Completer<PickedFile?>();

  // Two ways out, because a cancelled dialog fires no event at all in some
  // browsers: `change` when a file is chosen, and `cancel` where it exists.
  void finish(PickedFile? result) {
    if (!completer.isCompleted) completer.complete(result);
    input.remove();
  }

  input.onchange = (web.Event _) {
    final file = input.files?.item(0);
    if (file == null) {
      finish(null);
      return;
    }
    final reader = web.FileReader();
    reader.onload = (web.Event _) {
      final text = (reader.result as JSString?)?.toDart;
      finish(text == null ? null : (name: file.name, text: text));
    }.toJS;
    reader.onerror = ((web.Event _) => finish(null)).toJS;
    // The browser decodes UTF-8 for us; a 1251 file arrives with replacement
    // characters, which the screen shows in its preview rather than hiding.
    reader.readAsText(file, 'utf-8');
  }.toJS;

  input.oncancel = ((web.Event _) => finish(null)).toJS;

  input.click();
  return completer.future;
}
