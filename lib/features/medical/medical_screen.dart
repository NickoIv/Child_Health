import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/theme/app_theme.dart';
import '../../models/medical_record.dart';
import '../../providers.dart';
import '../reports/medical_report.dart';
import '../reports/report_data.dart';
import '../shared/photo_widgets.dart';
import '../shared/widgets.dart';
import 'record_form.dart';

/// Medical card: diagnoses, prescriptions, lab results and the PDF summary
/// for the doctor, per 2.5.
class MedicalScreen extends ConsumerStatefulWidget {
  const MedicalScreen({super.key});

  @override
  ConsumerState<MedicalScreen> createState() => _MedicalScreenState();
}

class _MedicalScreenState extends ConsumerState<MedicalScreen> {
  bool _building = false;

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(selectedChildProvider);
    if (child == null) return const NoChildPlaceholder();

    final recordsAsync = ref.watch(medicalRecordsProvider);
    if (recordsAsync.hasError) {
      return PageBody(
        children: [
          SectionCard(
            title: 'Медицинские записи',
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
          _ReportCard(building: _building, onGenerate: _generateReport),
          const SizedBox(height: 16),
          if (records.isEmpty)
            const SectionCard(
              title: 'Медицинские записи',
              icon: Icons.medical_information_outlined,
              child: EmptyState(
                icon: Icons.folder_open_outlined,
                message: 'Медицинских записей пока нет',
                hint: 'Добавьте визит к врачу или результаты анализов',
              ),
            )
          else
            for (final r in records) ...[
              _RecordCard(
                record: r,
                onDelete: () => _confirmDelete(r),
              ),
              const SizedBox(height: 16),
            ],
          const _PendingFeatures(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRecord,
        icon: const Icon(Icons.add),
        label: const Text('Добавить запись'),
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

  Future<void> _confirmDelete(MedicalRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: Text(
          'Запись «${record.diagnosis}» от ${shortDate.format(record.date)} '
          'будет удалена вместе с результатами анализов. Действие необратимо.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(medicalRepositoryProvider).delete(record.id);
    }
  }

  Future<void> _generateReport() async {
    final child = ref.read(selectedChildProvider);
    if (child == null || _building) return;

    setState(() => _building = true);
    try {
      final data = buildReportData(
        child: child,
        logs: ref.read(logsProvider).value ?? const [],
        records: ref.read(medicalRecordsProvider).value ?? const [],
        reminders: ref.read(remindersProvider).value ?? const [],
      );
      final bytes = await buildMedicalReport(data);

      // sharePdf rather than layoutPdf: on the web this hands the browser a
      // download, which is what a parent wants before an appointment. A print
      // preview would be an extra step between them and the file.
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Отчёт_${child.name}_${_fileDate(data.generatedAt)}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось сформировать отчёт: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _building = false);
    }
  }

  static String _fileDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.building, required this.onGenerate});

  final bool building;
  final Future<void> Function() onGenerate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Отчёт для врача',
      icon: Icons.picture_as_pdf_outlined,
      accentColor: VizPalette.slot(2, theme.brightness),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сводка на одном листе: антропометрия с оценкой по нормам ВОЗ, '
            'статистика болезней, анализы с отклонениями, статус вакцинации '
            'и вехи развития.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: building ? null : onGenerate,
            icon: building
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            label: Text(building ? 'Формирую…' : 'Скачать PDF'),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record, required this.onDelete});

  final MedicalRecord record;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
            tooltip: 'Удалить запись',
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
            Text('Назначения', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(record.prescriptions, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
          ],
          if (record.labResults.isNotEmpty) ...[
            Row(
              children: [
                Text('Результаты анализов',
                    style: theme.textTheme.labelLarge),
                const Spacer(),
                if (record.outOfRangeCount > 0)
                  Chip(
                    label: Text(
                      '${record.outOfRangeCount} вне нормы',
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
            Text('Сканы бланков', style: theme.textTheme.labelLarge),
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
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        headingRowHeight: 36,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 48,
        columns: const [
          DataColumn(label: Text('Показатель')),
          DataColumn(label: Text('Значение'), numeric: true),
          DataColumn(label: Text('Норма')),
          DataColumn(label: Text('')),
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
class _PendingFeatures extends StatelessWidget {
  const _PendingFeatures();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Ещё не реализовано',
      icon: Icons.construction_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Keep this list honest. It listed manual entry and scan
          // attachment for two releases after both shipped, because it was
          // written before the work rather than after it. A stale "not yet
          // implemented" is worse than none: it tells a parent to stop
          // looking for something that is right there.
          for (final line in const [
            'Редактирование сохранённой записи — пока только добавление и удаление',
            'Push-уведомления о приёме лекарств и визитах',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.radio_button_unchecked,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(line, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
