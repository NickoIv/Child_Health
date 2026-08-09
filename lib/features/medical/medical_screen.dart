import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/glass.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/development_log.dart';
import '../../models/medical_record.dart';
import '../../providers.dart';
import '../reports/export_sheet.dart';
import '../shared/photo_widgets.dart';
import '../shared/widgets.dart';
import 'record_form.dart';
import 'solids_card.dart';

/// Medical card: diagnoses, prescriptions, lab results and the PDF summary
/// for the doctor, per 2.5.
class MedicalScreen extends ConsumerStatefulWidget {
  const MedicalScreen({super.key});

  @override
  ConsumerState<MedicalScreen> createState() => _MedicalScreenState();
}

class _MedicalScreenState extends ConsumerState<MedicalScreen> {

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final child = ref.watch(selectedChildProvider);
    if (child == null) return const NoChildPlaceholder();

    final recordsAsync = ref.watch(medicalRecordsProvider);
    if (recordsAsync.hasError) {
      return PageBody(
        children: [
          SectionCard(
            title: l.medicalTitle,
            icon: Icons.medical_information_outlined,
            child: ErrorState(
              error: recordsAsync.error!,
              onRetry: () => ref.invalidate(medicalRecordsProvider),
            ),
          ),
        ],
      );
    }

    final records = recordsAsync.value ?? const <MedicalRecord>[];

    return Scaffold(
      body: PageBody(
        children: [
          _QuestionsCard(onAdd: _addQuestion),
          const SizedBox(height: 16),
          _ReportCard(onExport: _openExport),
          const SizedBox(height: 16),
          // Above the records rather than below them: what has been eaten is
          // asked about at every appointment in the first year, and a folder
          // of scans is asked about at almost none of them.
          SolidsCard(childId: child.id),
          const SizedBox(height: 16),
          if (records.isEmpty)
            SectionCard(
              title: l.medicalTitle,
              icon: Icons.medical_information_outlined,
              child: EmptyState(
                icon: Icons.folder_open_outlined,
                message: l.medicalEmpty,
                hint: l.medicalEmptyHint,
              ),
            )
          else
            for (final r in records) ...[
              _RecordCard(
                record: r,
                onEdit: () => _editRecord(r),
                onDelete: () => _confirmDelete(r),
              ),
              const SizedBox(height: 16),
            ],
        ],
      ),
      floatingActionButton: liftedFab(
        context,
        FloatingActionButton.extended(
          onPressed: _addRecord,
          icon: const Icon(Icons.add),
          label: Text(l.medicalAdd),
        ),
      ),
    );
  }

  Future<void> _addRecord() async {
    final child = ref.read(selectedChildProvider);
    if (child == null) return;

    final record = await showDialog<MedicalRecord>(
      context: context,
      builder: (_) => MedicalRecordForm(childId: child.id),
    );
    if (record == null) return;

    await ref.read(medicalRepositoryProvider).add(record);
  }

  Future<void> _editRecord(MedicalRecord record) async {
    final child = ref.read(selectedChildProvider);
    if (child == null) return;

    final updated = await showDialog<MedicalRecord>(
      context: context,
      builder: (_) => MedicalRecordForm(
        childId: child.id,
        existing: record,
      ),
    );
    if (updated == null) return;

    await ref.read(medicalRepositoryProvider).update(updated);
  }

  Future<void> _confirmDelete(MedicalRecord record) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.medicalDeleteTitle),
        content: Text(
          l.medicalDeleteBody(
            record.diagnosis,
            shortDate.format(record.date),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(medicalRepositoryProvider).delete(record.id);
    }
  }

  Future<void> _addQuestion() async {
    final child = ref.read(selectedChildProvider);
    if (child == null) return;

    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _QuestionDialog(),
    );
    if (text == null || text.isEmpty) return;

    await ref
        .read(logRepositoryProvider)
        .add(
          DevelopmentLog(
            id: '',
            childId: child.id,
            date: DateTime.now(),
            type: LogType.question,
            title: text,
          ),
        );
  }

  /// Which period, then the file. The choice lives in a sheet rather than on
  /// the card: it is asked once, and a row of chips on a card a parent reads
  /// every week would be three permanent buttons for a rare decision.
  Future<void> _openExport() async {
    final child = ref.read(selectedChildProvider);
    if (child == null) return;
    await showExportSheet(context, childId: child.id);
  }
}

/// Questions to raise at the next appointment.
///
/// They come to mind at 2am and vanish the moment a doctor asks "any
/// questions?". Written down here, they also print into the report, so the
/// list is in hand rather than in memory.
class _QuestionsCard extends ConsumerWidget {
  const _QuestionsCard({required this.onAdd});

  final Future<void> Function() onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final questions = ref.watch(doctorQuestionsProvider);

    return SectionCard(
      title: l.medicalAskDoctor,
      icon: Icons.help_outline,
      accentColor: VizPalette.slot(1, theme.brightness),
      action: TextButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add, size: 18),
        label: Text(l.medicalWriteDown),
      ),
      child: questions.isEmpty
          ? Text(
              l.medicalQuestionsHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              children: [
                for (final q in questions)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.circle_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(q.title),
                    subtitle: Text(shortDate.format(q.date)),
                    trailing: IconButton(
                      tooltip: l.medicalAsked,
                      icon: const Icon(Icons.check, size: 20),
                      onPressed: () =>
                          ref.read(logRepositoryProvider).delete(q.id),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _QuestionDialog extends StatefulWidget {
  const _QuestionDialog();

  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.medicalAskDoctor),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _controller,
          autofocus: true,
          maxLines: 3,
          minLines: 1,
          decoration: InputDecoration(hintText: l.medicalQuestionHint),
          onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(_controller.text.trim()),
          child: Text(l.commonSave),
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.onExport});

  final Future<void> Function() onExport;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SectionCard(
      title: l.medicalReport,
      icon: Icons.picture_as_pdf_outlined,
      accentColor: VizPalette.slot(2, theme.brightness),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.medicalReportHint,
            style: theme.textTheme.bodyMedium,
          ),
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

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  final MedicalRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SectionCard(
      title: record.diagnosis,
      icon: Icons.medical_information_outlined,
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            shortDate.format(record.date),
            style: theme.textTheme.bodySmall,
          ),
          IconButton(
            tooltip: l.diaryEditEntry,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
          IconButton(
            tooltip: l.medicalDeleteTitle,
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (record.doctor.isNotEmpty) ...[
            Text(record.doctor, style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
            const SizedBox(height: 12),
          ],
          if (record.prescriptions.isNotEmpty) ...[
            Text(l.medicalPrescriptions, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(record.prescriptions, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
          ],
          if (record.labResults.isNotEmpty) ...[
            // Wrap, not Row with a Spacer: on a phone the heading plus the
            // "вне нормы" chip ran 114px past the edge.
            Wrap(
              spacing: 10,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(l.medicalLabResults, style: theme.textTheme.labelLarge),
                if (record.outOfRangeCount > 0)
                  Chip(
                    label: Text(
                      l.medicalOutOfRange(record.outOfRangeCount),
                      style: const TextStyle(fontSize: 12),
                    ),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                    backgroundColor:
                        StatusColors.warning.withValues(alpha: 0.16),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _LabTable(results: record.labResults),
          ],
          if (record.files.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l.medicalScans, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            PhotoStrip(photoIds: record.files),
          ],
        ],
      ),
    );
  }
}

class _LabTable extends StatelessWidget {
  const _LabTable({required this.results});

  final List<LabResult> results;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        headingRowHeight: 36,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 48,
        columns: [
          DataColumn(label: Text(l.medicalIndicator)),
          DataColumn(label: Text(l.medicalValue), numeric: true),
          DataColumn(label: Text(l.medicalReference)),
          const DataColumn(label: Text('')),
        ],
        rows: [
          for (final r in results)
            DataRow(
              cells: [
                DataCell(Text(r.name)),
                DataCell(
                  Text(
                    '${r.value} ${r.unit}',
                    style: TextStyle(
                      fontWeight: r.isWithinReference == false
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: r.isWithinReference == false
                          ? StatusColors.alert
                          : null,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    r.referenceLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                DataCell(
                  switch (r.isWithinReference) {
                    true => const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: StatusColors.normal,
                    ),
                    false => const Icon(
                      Icons.error_outline,
                      size: 18,
                      color: StatusColors.alert,
                    ),
                    null => const SizedBox.shrink(),
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Honest placeholder: these parts of 2.5 need Firebase Storage and the `pdf`
/// package, neither of which is wired up yet.
