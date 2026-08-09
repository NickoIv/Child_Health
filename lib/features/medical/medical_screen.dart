import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_snack.dart';
import '../../core/theme/glass.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
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
          const _VisitPrepCard(),
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

    // Taken before the dialog, not after: a BuildContext read across an await
    // is a context that may no longer be in the tree.
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context);

    final record = await showDialog<MedicalRecord>(
      context: context,
      builder: (_) => MedicalRecordForm(childId: child.id),
    );
    if (record == null) return;

    await ref.read(medicalRepositoryProvider).add(record);
    messenger.showAppSnack(
      appSnack(l.medicalRecordSaved, kind: SnackKind.done),
    );
  }

  Future<void> _editRecord(MedicalRecord record) async {
    final child = ref.read(selectedChildProvider);
    if (child == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context);

    final updated = await showDialog<MedicalRecord>(
      context: context,
      builder: (_) => MedicalRecordForm(
        childId: child.id,
        existing: record,
      ),
    );
    if (updated == null) return;

    await ref.read(medicalRepositoryProvider).update(updated);
    messenger.showAppSnack(
      appSnack(l.medicalRecordSaved, kind: SnackKind.done),
    );
  }

  Future<void> _confirmDelete(MedicalRecord record) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
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
      messenger.showAppSnack(
        appSnack(l.medicalRecordDeleted, kind: SnackKind.done),
      );
    }
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

/// The appointment, one tap away.
///
/// The card is deliberately thin: what to ask, what is due and what happened
/// since last time is a screen of its own, and repeating any of it here would
/// give a parent two places to keep the same list.
class _VisitPrepCard extends ConsumerWidget {
  const _VisitPrepCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final questions = ref.watch(doctorQuestionsProvider).length;

    return SectionCard(
      title: l.visitTitle,
      icon: Icons.event_available_outlined,
      accentColor: VizPalette.slot(1, theme.brightness),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.visitCardHint, style: theme.textTheme.bodyMedium),
          if (questions > 0) ...[
            const SizedBox(height: 6),
            Text(
              l.visitQuestionsWaiting(questions),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 14),
          FilledButton.tonalIcon(
            onPressed: () => context.go(visitPath),
            icon: const Icon(Icons.checklist_rtl_outlined),
            label: Text(l.visitOpen),
          ),
        ],
      ),
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
