import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/care/visit_prep.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/development_log.dart';
import '../../models/medical_record.dart';
import '../../models/reminder.dart';
import '../../providers.dart';
import '../reports/export_sheet.dart';
import '../shared/widgets.dart';
import 'questions_card.dart';

/// The appointment, before it starts.
///
/// One screen that answers the two questions a parent walks in with — «о чём
/// я хотела спросить» and «что у нас было с прошлого раза» — out of entries
/// she has already made. It states and never advises: every line is a fact
/// with a date on it, and the doctor is the one who draws conclusions from
/// them.
class VisitPrepScreen extends ConsumerWidget {
  const VisitPrepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider);
    if (child == null) return const NoChildPlaceholder();

    final prep = buildVisitPrep(
      child: child,
      logs: ref.watch(logsProvider).value ?? const <DevelopmentLog>[],
      reminders: ref.watch(remindersProvider).value ?? const <Reminder>[],
      records:
          ref.watch(medicalRecordsProvider).value ?? const <MedicalRecord>[],
    );

    return Scaffold(
      body: PageBody(
        children: [
          _ChecklistCard(prep: prep),
          const SizedBox(height: 16),
          const DoctorQuestionsCard(),
          const SizedBox(height: 16),
          _HistoryCard(prep: prep),
          const SizedBox(height: 16),
          _TakeWithYouCard(
            onExport: () => showExportSheet(context, childId: child.id),
          ),
        ],
      ),
    );
  }
}

/// What is ready and what is not: weight, doses, food.
///
/// Three rows rather than a page of numbers, because this is read standing in
/// a hallway with a coat on.
class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({required this.prep});

  final VisitPrep prep;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SectionCard(
      title: l.visitTitle,
      icon: Icons.checklist_rtl_outlined,
      accentColor: VizPalette.slot(1, theme.brightness),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PrepRow(
            state: prep.measurementState,
            title: l.visitMeasureTitle,
            detail: switch (prep.lastMeasurement) {
              null => l.visitMeasureNone,
              final m => l.visitMeasuredAt(
                shortDate.format(m.date),
                prep.measurementAgeDays ?? 0,
              ),
            },
          ),
          Divider(color: Warm.hairline(theme.brightness), height: 24),
          _PrepRow(
            state: prep.vaccineState,
            title: l.visitVaccinesTitle,
            detail: _vaccineDetail(l),
          ),
          if (prep.hasSolids) ...[
            Divider(color: Warm.hairline(theme.brightness), height: 24),
            _PrepRow(
              state: prep.solidsState,
              title: l.solidsTitle,
              detail: _solidsDetail(l),
            ),
          ],
        ],
      ),
    );
  }

  /// The next dose, named in the language on screen rather than in the
  /// Russian the plan was written in — see [localizedVaccinationName].
  String _vaccineDetail(AppLocalizations l) {
    final next = prep.nextVaccine;
    if (next == null) return l.visitVaccinesNone;

    final name = localizedVaccinationName(l, next.title);
    final date = shortDate.format(next.scheduledTime);
    return next.scheduledTime.isBefore(prep.now)
        ? l.visitVaccineOverdue(name, date)
        : l.visitVaccineDue(name, date);
  }

  String _solidsDetail(AppLocalizations l) {
    final lines = <String>[
      for (final food in prep.watchedFoods)
        '${food.name} — ${l.solidWatch(shortDate.format(food.watchUntil))}',
      for (final food in prep.reactedFoods)
        '${food.name} — ${food.reactions.first.description.trim()}',
    ];
    if (lines.isEmpty) return l.visitFoodsNew(prep.newFoods.length);
    return lines.join('\n');
  }
}

/// One line of the checklist: a mark, a name, and the fact under it.
class _PrepRow extends StatelessWidget {
  const _PrepRow({
    required this.state,
    required this.title,
    required this.detail,
  });

  final PrepState state;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // The mark says what state the line is in and nothing more. Nothing here
    // is a failing grade: an empty question list is a calm week.
    final (icon, color) = switch (state) {
      PrepState.ready => (
        Icons.check_circle_outline,
        StatusColors.normal,
      ),
      PrepState.attention => (
        Icons.error_outline,
        StatusColors.warning,
      ),
      PrepState.missing => (
        Icons.radio_button_unchecked,
        theme.colorScheme.onSurfaceVariant,
      ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: state == PrepState.attention
                      ? color
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// What happened since the last appointment.
///
/// Counted over the window the card names, because a number without the
/// period it was taken over is not an answer to «как он это время».
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.prep});

  final VisitPrep prep;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final quiet = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return SectionCard(
      title: l.visitHistoryTitle,
      icon: Icons.history,
      accentColor: VizPalette.slot(3, theme.brightness),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            prep.lastVisit == null
                ? l.visitSinceDays(prep.daysCovered)
                : l.visitSinceVisit(shortDate.format(prep.lastVisit!)),
            style: quiet,
          ),
          const SizedBox(height: 12),
          if (!prep.hasHistory)
            Text(l.visitHistoryEmpty, style: quiet)
          else ...[
            if (prep.sickDays > 0)
              _Fact(text: l.visitSickDays(prep.sickDays)),
            if (prep.maxTemperature != null)
              _Fact(
                text: l.visitMaxTemperature(
                  prep.maxTemperature!.toStringAsFixed(1),
                ),
              ),
            if (prep.medicines.isNotEmpty) ...[
              _Fact(text: l.visitMedicines(prep.medicines.length)),
              // The doses themselves, newest first — the question at the
              // appointment is «чем лечили», and the answer is the names.
              for (final medicine in prep.medicines.take(5))
                Padding(
                  padding: const EdgeInsets.only(left: 26, bottom: 4),
                  child: Text(
                    '${shortDate.format(medicine.date)} — '
                    '${medicine.description.trim().isEmpty ? localizedLogTitle(l, medicine) : medicine.description.trim()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Icon(
              Icons.circle,
              size: 6,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// The sheet of paper.
class _TakeWithYouCard extends StatelessWidget {
  const _TakeWithYouCard({required this.onExport});

  final Future<void> Function() onExport;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SectionCard(
      title: l.visitTakeTitle,
      icon: Icons.picture_as_pdf_outlined,
      accentColor: VizPalette.slot(2, theme.brightness),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.visitTakeHint, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onExport,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(l.reportExport),
          ),
        ],
      ),
    );
  }
}