import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/care/solids.dart';
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
        // Directly under feeding, because a spoon is feeding — and because
        // the question it answers is asked in the same breath as «сколько
        // раз ест».
        if (report.hasFoods) ..._solids(report, l, date),
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
        // Last, and with a blank column beside each one: the counts are read
        // first and the conversation happens afterwards, and an answer
        // written on this sheet is the only part of the appointment that
        // otherwise goes home in nobody's memory.
        if (report.hasQuestions) ..._questions(report, l, date),
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

/// Which foods have been given, and what followed.
///
/// Four columns and no verdict. The right-hand one carries her own sentence —
/// «сыпь на щеках к вечеру» — because that is what a doctor asks for, and a
/// red dot standing in for it would be the app deciding what she saw.
List<pw.Widget> _solids(
  PeriodReport report,
  AppLocalizations l,
  DateFormat date,
) => [
  pw.SizedBox(height: 18),
  _heading(l.solidsTitle),
  pw.SizedBox(height: 6),
  pw.Table(
    columnWidths: const {
      0: pw.FlexColumnWidth(2),
      1: pw.FixedColumnWidth(66),
      2: pw.FixedColumnWidth(46),
      3: pw.FlexColumnWidth(3),
    },
    border: pw.TableBorder.symmetric(
      inside: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
    ),
    children: [
      pw.TableRow(
        children: [
          _cell(l.reportFoodName, bold: true),
          _cell(l.reportFoodFirst, bold: true),
          _cell(l.reportFoodTimes, bold: true, align: pw.TextAlign.right),
          _cell(l.reportFoodReaction, bold: true),
        ],
      ),
      for (final food in report.foods)
        pw.TableRow(
          children: [
            _cell(food.name),
            _cell(date.format(food.firstAt)),
            _cell(
              food.times == 0 ? '' : '${food.times}',
              align: pw.TextAlign.right,
            ),
            _cell(_reactionText(food, report.to, l, date)),
          ],
        ),
    ],
  ),
];

/// Everything known about how this food went, as one cell.
String _reactionText(
  FoodRecord food,
  DateTime now,
  AppLocalizations l,
  DateFormat date,
) {
  if (food.hadReaction) {
    return [
      for (final r in food.reactions)
        '${date.format(r.date)} — ${r.description.trim()}',
    ].join('\n');
  }
  if (food.isUnderWatchAt(now)) {
    return l.solidWatch(date.format(food.watchUntil));
  }
  return '';
}

/// The questions, and room to write the answers next to them.
List<pw.Widget> _questions(
  PeriodReport report,
  AppLocalizations l,
  DateFormat date,
) => [
  pw.SizedBox(height: 18),
  _heading(l.reportSectionQuestions),
  pw.SizedBox(height: 6),
  pw.Table(
    columnWidths: const {
      0: pw.FlexColumnWidth(3),
      1: pw.FlexColumnWidth(2),
    },
    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
    children: [
      pw.TableRow(
        children: [
          _cell(l.reportQuestion, bold: true),
          _cell(l.reportAnswer, bold: true),
        ],
      ),
      for (final q in report.questions)
        pw.TableRow(
          children: [
            _cell('${date.format(q.at)} — ${q.text}'),
            // Deliberately blank, and tall enough to write two lines in.
            pw.Container(height: 34),
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

pw.Widget _cell(
  String text, {
  pw.TextAlign align = pw.TextAlign.left,
  bool bold = false,
}) => pw.Padding(
  padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
  child: pw.Text(
    text,
    textAlign: align,
    style: pw.TextStyle(
      fontSize: 10,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: bold ? PdfColors.grey700 : null,
    ),
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
