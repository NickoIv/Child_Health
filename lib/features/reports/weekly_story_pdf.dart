import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/analytics/weekly_story.dart';
import '../../core/l10n/labels.dart';
import '../../l10n/app_localizations.dart';
import '../../models/child.dart';

/// Fonts are parsed once, exactly as the medical report does.
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

/// One page a grandmother would put on the fridge.
///
/// The opposite document to the medical report in every decision: one page
/// rather than several, a photograph rather than tables, a warm title rather
/// than a heading, and four numbers rather than everything that was recorded.
/// It carries no disclaimer because it makes no claim — there is nothing on it
/// a doctor could mistake for a finding.
Future<Uint8List> renderWeeklyStory(
  WeeklyStory story,
  Child child,
  AppLocalizations l, {
  Uint8List? cover,
  String? localeName,
}) async {
  final date = DateFormat('d MMMM', localeName);

  final doc = pw.Document(
    title: '${storyTitle(l, story.title)} — ${child.name}',
    author: l.appTitle,
  );

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: await _loadTheme(),
      margin: const pw.EdgeInsets.all(40),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            storyTitle(l, story.title),
            style: pw.TextStyle(
              fontSize: 26,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            '${child.name} · '
            '${l.reportRange(date.format(story.from), date.format(story.to))}',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 20),

          // The photograph is the point of the page, so it gets the room. A
          // fixed height rather than the image's own: a portrait snapshot at
          // full width would push the numbers onto a second page.
          if (cover != null) ...[
            pw.ClipRRect(
              horizontalRadius: 12,
              verticalRadius: 12,
              child: pw.Container(
                height: 380,
                width: double.infinity,
                child: pw.Image(
                  pw.MemoryImage(cover),
                  fit: pw.BoxFit.cover,
                ),
              ),
            ),
            pw.SizedBox(height: 24),
          ],

          pw.Wrap(
            spacing: 40,
            runSpacing: 20,
            children: [
              _fact('${story.feedings}', l.storyFeedings),
              _fact(localizedDuration(l, story.sleepMinutes), l.storySleep),
              _fact('${story.nappies}', l.storyNappies),
              if (story.hasBestNight)
                _fact(
                  localizedDuration(l, story.bestNightMinutes),
                  l.storyBestNight,
                ),
            ],
          ),
        ],
      ),
    ),
  );

  return doc.save();
}

const _ink = PdfColors.blueGrey800;

pw.Widget _fact(String value, String label) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  mainAxisSize: pw.MainAxisSize.min,
  children: [
    pw.Text(
      value,
      style: pw.TextStyle(
        fontSize: 22,
        fontWeight: pw.FontWeight.bold,
        color: _ink,
      ),
    ),
    pw.SizedBox(height: 2),
    pw.Text(
      label,
      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
    ),
  ],
);

/// The warm title, in words. Shared by the card and the page so the file a
/// parent sends is headed the same way as the card they tapped.
String storyTitle(AppLocalizations l, StoryTitle title) => switch (title) {
  StoryTitle.care => l.storyTitleCare,
  StoryTitle.growing => l.storyTitleGrowing,
  StoryTitle.moments => l.storyTitleMoments,
};

/// `story_Aisha.pdf` — a name an inbox can hold three of.
String storyFilename(String childName) {
  final safe = childName
      .trim()
      .replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  return safe.isEmpty ? 'week.pdf' : 'week_$safe.pdf';
}
