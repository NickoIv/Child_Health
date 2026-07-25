import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'report_data.dart';

final _date = DateFormat('dd.MM.yyyy');
final _dateTime = DateFormat('dd.MM.yyyy HH:mm');

/// Fonts are loaded once and reused: parsing a 500 KB TTF on every report
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

/// Renders the summary a parent hands to a paediatrician (requirement 2.5).
///
/// Deliberately dense and free of decoration: this is read in a five-minute
/// appointment, and anything the doctor has to scroll past is a cost.
Future<Uint8List> buildMedicalReport(ReportData data) async {
  final doc = pw.Document(
    title: 'Медицинский отчёт — ${data.child.name}',
    author: 'Календарь развития и здоровья ребёнка',
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: await _loadTheme(),
      margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 40),
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Text(
          'Страница ${context.pageNumber} из ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ),
      build: (context) => [
        _header(data),
        pw.SizedBox(height: 16),
        _summary(data),
        if (data.latestAssessments.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          _growthAssessment(data),
        ],
        if (data.measurements.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          _measurementTable(data),
        ],
        if (data.records.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          _medicalRecords(data),
        ],
        if (data.overdueVaccinations.isNotEmpty ||
            data.upcomingVaccinations.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          _vaccinations(data),
        ],
        if (data.milestones.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          _milestones(data),
        ],
        pw.SizedBox(height: 20),
        _disclaimer(),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _header(ReportData data) {
  final child = data.child;
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Медицинский отчёт',
        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        'Сформирован ${_dateTime.format(data.generatedAt)}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 12),
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Row(
          children: [
            _field('Ребёнок', child.name),
            _field('Дата рождения', _date.format(child.birthDate)),
            _field('Возраст', child.ageLabelAt(data.generatedAt)),
            _field('Пол', child.gender.label),
          ],
        ),
      ),
    ],
  );
}

pw.Widget _field(String label, String value) => pw.Expanded(
  child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        label,
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 2),
      pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
    ],
  ),
);

pw.Widget _summary(ReportData data) => _section('Сводка', [
  pw.Row(
    children: [
      _stat('${data.illnessDays}', 'дней болезни'),
      _stat('${data.illnessEpisodes}', 'эпизодов'),
      _stat('${data.measurements.length}', 'измерений'),
      _stat('${data.records.length}', 'мед. записей'),
      _stat('${data.overdueVaccinations.length}', 'прививок просрочено'),
    ],
  ),
]);

pw.Widget _stat(String value, String caption) => pw.Expanded(
  child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        value,
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
      pw.Text(
        caption,
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
      ),
    ],
  ),
);

pw.Widget _growthAssessment(ReportData data) => _section(
  'Оценка физического развития по нормам ВОЗ',
  [
    pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1.5),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(1.2),
        4: pw.FlexColumnWidth(2.5),
      },
      children: [
        _row(
          ['Показатель', 'Значение', 'Z-оценка', 'Перцентиль', 'Заключение'],
          header: true,
        ),
        for (final a in data.latestAssessments)
          _row([
            a.metric.label,
            '${a.value.toStringAsFixed(1)} ${a.metric.unit}',
            a.zScore.toStringAsFixed(2),
            '${a.percentile.round()}',
            a.verdict.label,
          ]),
      ],
    ),
    pw.SizedBox(height: 6),
    pw.Text(
      'Справочные таблицы ВОЗ в приложении сокращены и приведены для '
      'ориентира. Оценка не является медицинским заключением.',
      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
    ),
  ],
);

pw.Widget _measurementTable(ReportData data) {
  // Newest first, and capped: a doctor wants the trend, not five years of
  // rows. The full history stays in the app.
  final rows = data.measurements.reversed.take(12).toList();
  return _section('Антропометрия', [
    pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        _row(['Дата', 'Возраст', 'Вес, кг', 'Рост, см', 'Температура'],
            header: true),
        for (final m in rows)
          _row([
            _date.format(m.date),
            '${data.child.ageInMonthsAt(m.date)} мес.',
            m.metrics.weightKg?.toStringAsFixed(1) ?? '—',
            m.metrics.heightCm?.toStringAsFixed(1) ?? '—',
            m.metrics.temperatureC == null
                ? '—'
                : '${m.metrics.temperatureC!.toStringAsFixed(1)} °C',
          ]),
      ],
    ),
    if (data.measurements.length > rows.length) ...[
      pw.SizedBox(height: 4),
      pw.Text(
        'Показаны последние ${rows.length} из ${data.measurements.length} измерений.',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
      ),
    ],
  ]);
}

pw.Widget _medicalRecords(ReportData data) => _section(
  'Медицинские записи и анализы',
  [
    for (final r in data.records) ...[
      pw.Text(
        '${_date.format(r.date)} — ${r.diagnosis}',
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
      if (r.doctor.isNotEmpty)
        pw.Text(
          r.doctor,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      if (r.prescriptions.isNotEmpty) ...[
        pw.SizedBox(height: 2),
        pw.Text(
          'Назначения: ${r.prescriptions}',
          style: const pw.TextStyle(fontSize: 9),
        ),
      ],
      if (r.labResults.isNotEmpty) ...[
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          children: [
            _row(['Показатель', 'Значение', 'Норма', ''], header: true),
            for (final l in r.labResults)
              _row(
                [
                  l.name,
                  '${l.value} ${l.unit}',
                  l.referenceLabel,
                  l.isWithinReference == false ? 'вне нормы' : '',
                ],
                highlight: l.isWithinReference == false,
              ),
          ],
        ),
      ],
      pw.SizedBox(height: 10),
    ],
  ],
);

pw.Widget _vaccinations(ReportData data) => _section('Вакцинация', [
  if (data.overdueVaccinations.isNotEmpty) ...[
    pw.Text(
      'Просрочено:',
      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
    ),
    for (final v in data.overdueVaccinations.take(10))
      pw.Bullet(
        text: '${v.title} — с ${_date.format(v.scheduledTime)}',
        style: const pw.TextStyle(fontSize: 9),
      ),
    pw.SizedBox(height: 6),
  ],
  if (data.upcomingVaccinations.isNotEmpty) ...[
    pw.Text(
      'Предстоит:',
      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
    ),
    for (final v in data.upcomingVaccinations)
      pw.Bullet(
        text: '${v.title} — ${_date.format(v.scheduledTime)}',
        style: const pw.TextStyle(fontSize: 9),
      ),
  ],
]);

pw.Widget _milestones(ReportData data) => _section('Вехи развития', [
  for (final m in data.milestones.take(15))
    pw.Bullet(
      text: '${_date.format(m.date)} — ${m.title}',
      style: const pw.TextStyle(fontSize: 9),
    ),
]);

pw.Widget _disclaimer() => pw.Container(
  padding: const pw.EdgeInsets.all(10),
  decoration: pw.BoxDecoration(
    color: PdfColors.amber50,
    borderRadius: pw.BorderRadius.circular(4),
  ),
  child: pw.Text(
    'Отчёт сформирован автоматически из записей, внесённых родителем. '
    'Он не является медицинским документом, диагнозом или назначением '
    'и предназначен только для того, чтобы врачу было проще увидеть '
    'историю. Все решения принимает врач.',
    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
  ),
);

pw.Widget _section(String title, List<pw.Widget> children) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Text(
      title,
      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
    ),
    pw.Divider(color: PdfColors.grey400, thickness: 0.5),
    pw.SizedBox(height: 4),
    ...children,
  ],
);

pw.TableRow _row(
  List<String> cells, {
  bool header = false,
  bool highlight = false,
}) {
  return pw.TableRow(
    decoration: pw.BoxDecoration(
      color: header
          ? PdfColors.grey200
          : highlight
          ? PdfColors.red50
          : null,
    ),
    children: [
      for (final c in cells)
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          child: pw.Text(
            c,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: highlight ? PdfColors.red900 : null,
            ),
          ),
        ),
    ],
  );
}
