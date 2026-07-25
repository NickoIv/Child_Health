import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/medical_record.dart';
import '../../providers.dart';
import '../shared/widgets.dart';

/// Medical card: diagnoses, prescriptions and lab results, per 2.5.
class MedicalScreen extends ConsumerWidget {
  const MedicalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider);
    if (child == null) return const NoChildPlaceholder();

    final records =
        ref.watch(medicalRecordsProvider).value ?? const <MedicalRecord>[];

    return PageBody(
      children: [
        if (records.isEmpty)
          const SectionCard(
            title: 'Медицинские записи',
            icon: Icons.medical_information_outlined,
            child: EmptyState(
              icon: Icons.folder_open_outlined,
              message: 'Медицинских записей пока нет',
            ),
          )
        else
          for (final r in records) ...[
            _RecordCard(record: r),
            const SizedBox(height: 16),
          ],
        const _PendingFeatures(),
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record});

  final MedicalRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: record.diagnosis,
      icon: Icons.medical_information_outlined,
      action: Text(
        shortDate.format(record.date),
        style: theme.textTheme.bodySmall,
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
          for (final line in const [
            'Загрузка сканов и фото бланков — нужен Firebase Storage',
            'Генерация сводного PDF-отчёта для врача — нужен пакет pdf',
            'Ручной ввод новых медицинских записей',
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
