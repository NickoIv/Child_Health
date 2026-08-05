import 'dart:typed_data';

import 'package:printing/printing.dart';

/// Hands a finished report to the platform, and nowhere else.
///
/// On Android and iOS the bytes are written into the app's own cache
/// directory and the system share sheet opens over that file, so the parent
/// picks WhatsApp, mail or Files herself and the operating system reclaims
/// the copy afterwards. On the web the same bytes become a blob the browser
/// downloads straight away — there is no sheet to offer.
///
/// What matters more than either is what does not happen: the report is never
/// uploaded, never given a link and never kept anywhere the app can read it
/// back. A child's fortnight of temperatures leaves the phone only if the
/// mother sends it herself.
Future<void> shareReportPdf({
  required Uint8List bytes,
  required String filename,
}) {
  return Printing.sharePdf(bytes: bytes, filename: filename);
}

/// A filename a temporary file can actually be called.
///
/// The child's name goes in the filename so a doctor's inbox with three
/// attachments in it stays readable, and children's names arrive with spaces,
/// apostrophes and — on Android, fatally — slashes.
String reportFilename(String childName, int days) {
  final safe = childName
      .trim()
      .replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  return safe.isEmpty ? 'report_${days}d.pdf' : 'report_${safe}_${days}d.pdf';
}
