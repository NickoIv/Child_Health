import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/l10n/labels.dart';
import '../../l10n/app_localizations.dart';
import 'period_report.dart';

/// Fonts are loaded once and reused: parsing a 500 KB TTF on every export
/// would be a visible pause.
pw.ThemeData? _theme;

Future<pw.ThemeData> _loadTheme() async {
  if (_theme != null) return _theme!;
  final regular = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
  );
  final bold = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
  );
  return _theme = pw.ThemeData.withFont(base: regular, bold: bold);
}

/// One page of counts, for a five-minute appointment.
///
/// A4, one family, no rules, no colour outside the headings and no chart. The
/// document says what was recorded and stops: a doctor reading it should never
/// have to work out which numbers came from a parent and which from an app
/// with an opinion.
Future<Uint8List> renderPeriodReport(
  PeriodReport report,
  AppLocalizations l, {
  String? localeName,
}) async {
  final date = DateFormat('dd.MM.yyyy', localeName);
  final dateTime = DateFormat('dd.MM.yyyy HH:mm', localeName);

  final doc = pw.Document(
    title: '${l.reportTitle} — ${report.child.name}',
    author: l.appTitle,
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: await _loadTheme(),
      margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 44),
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 10),
        child: pw.Text(
          l.reportPage(context.pageNumber, context.pagesCount),
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ),
      build: (context) => [
        _header(report, l, date),
        if (report.hasSleep) ..._section(l.reportSectionSleep, [
          if (report.nights > 0)
            (l.reportAvgNight, localizedDuration(l, report.averageNightMinutes)),
          if (report.daysWithNaps > 0)
            (
              l.reportAvgDay,
              localizedDuration(l, report.averageDayNapMinutes),
            ),
          if (report.nights > 0)
            (l.reportAvgWakings, report.averageWakings.toStringAsFixed(1)),
        ]),
        if (report.hasFeeding) ..._section(l.reportSectionFeeding, [
          (l.reportFeedingsTotal, '${report.feedings}'),
          if (report.breastFeedings > 0)
            (l.reportBreast, '${report.breastFeedings}'),
          if (report.bottleFeedings > 0)
            (l.reportBottle, '${report.bottleFeedings}'),
        ]),
        if (report.hasNappies) ..._section(l.reportSectionNappies, [
          if (report.wetNappies > 0) (l.nappyWet, '${report.wetNappies}'),
          if (report.dirtyNappies > 0) (l.nappyDirty, '${report.dirtyNappies}'),
          if (report.bothNappies > 0) (l.nappyBoth, '${report.bothNappies}'),
        ]),
        if (report.hasTemperature) ..._section(l.reportSectionTemperature, [
          (l.reportTempMax, '${report.maxTemperature!.toStringAsFixed(1)} °C'),
          (l.reportTempMin, '${report.minTemperature!.toStringAsFixed(1)} °C'),
          (l.reportTempCount, '${report.temperatureCount}'),
        ]),
        if (report.hasMedicines)
          ..._entries(l.reportSectionMedicines, report.medicines, dateTime),
        if (report.hasNotes)
          ..._entries(l.reportSectionNotes, report.notes, dateTime),
        pw.SizedBox(height: 24),
        _disclaimer(l),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _header(PeriodReport report, AppLocalizations l, DateFormat date) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        report.child.name,
        style: pw.TextStyle(
          fontSize: 20,
          fontWeight: pw.FontWeight.bold,
          color: _accent,
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        '${l.childBirthDate}: ${date.format(report.child.birthDate)}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
      ),
      pw.Text(
        '${l.reportPeriod}: '
        '${l.reportRange(date.format(report.from), date.format(report.to))} '
        '(${l.reportPeriodDays(report.period.days)})',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
      ),
      pw.SizedBox(height: 6),
      pw.Divider(height: 1, color: PdfColors.grey400),
    ],
  );
}

/// The only colour in the document, and only on the headings.
const _accent = PdfColors.blueGrey800;

List<pw.Widget> _section(String title, List<(String, String)> rows) {
  final visible = rows.where((r) => r.$2.isNotEmpty).toList();
  if (visible.isEmpty) return const [];

  return [
    pw.SizedBox(height: 18),
    _heading(title),
    pw.SizedBox(height: 6),
    pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(1),
      },
      border: pw.TableBorder.symmetric(
        inside: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      ),
      children: [
        for (final (label, value) in visible)
          pw.TableRow(
            children: [
              _cell(label),
              _cell(value, align: pw.TextAlign.right),
            ],
          ),
      ],
    ),
  ];
}

List<pw.Widget> _entries(
  String title,
  List<ReportEntry> entries,
  DateFormat dateTime,
) => [
  pw.SizedBox(height: 18),
  _heading(title),
  pw.SizedBox(height: 6),
  pw.Table(
    columnWidths: const {
      0: pw.FixedColumnWidth(110),
      1: pw.FlexColumnWidth(),
    },
    border: pw.TableBorder.symmetric(
      inside: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
    ),
    children: [
      for (final entry in entries)
        pw.TableRow(
          children: [
            _cell(dateTime.format(entry.at)),
            _cell(entry.text),
          ],
        ),
    ],
  ),
];

pw.Widget _heading(String text) => pw.Text(
  text,
  style: pw.TextStyle(
    fontSize: 13,
    fontWeight: pw.FontWeight.bold,
    color: _accent,
  ),
);

pw.Widget _cell(String text, {pw.TextAlign align = pw.TextAlign.left}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: const pw.TextStyle(fontSize: 10),
      ),
    );

/// The line that says what this document is not.
pw.Widget _disclaimer(AppLocalizations l) => pw.Container(
  padding: const pw.EdgeInsets.all(10),
  decoration: pw.BoxDecoration(
    border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
  ),
  child: pw.Text(
    l.reportDisclaimer,
    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
  ),
);
