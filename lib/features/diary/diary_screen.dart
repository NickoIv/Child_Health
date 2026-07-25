import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/development_log.dart';
import '../../providers.dart';
import '../shared/widgets.dart';

/// Chronological feed of diary entries with filtering by type, per 2.2.
class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  LogType? _filter;

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(selectedChildProvider);
    if (child == null) return const NoChildPlaceholder();

    final logsAsync = ref.watch(logsProvider);
    if (logsAsync.hasError) {
      return PageBody(
        children: [
          SectionCard(
            title: 'Лента событий',
            icon: Icons.auto_stories_outlined,
            child: ErrorState(
              error: logsAsync.error!,
              onRetry: () => ref.invalidate(logsProvider),
            ),
          ),
        ],
      );
    }

    final logs = logsAsync.value ?? const <DevelopmentLog>[];
    final visible = _filter == null
        ? logs
        : logs.where((l) => l.type == _filter).toList();

    return Scaffold(
      body: PageBody(
        children: [
          _FilterBar(
            selected: _filter,
            onChanged: (t) => setState(() => _filter = t),
          ),
          const SizedBox(height: 16),
          if (visible.isEmpty)
            const SectionCard(
              title: 'Лента событий',
              icon: Icons.auto_stories_outlined,
              child: EmptyState(
                icon: Icons.edit_note,
                message: 'Записей пока нет',
                hint: 'Нажмите «Добавить запись», чтобы создать первую',
              ),
            )
          else
            SectionCard(
              title: 'Лента событий',
              icon: Icons.auto_stories_outlined,
              action: Text(
                plural(visible.length, 'запись', 'записи', 'записей'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < visible.length; i++) ...[
                    if (i > 0) const Divider(height: 24),
                    _LogTile(
                      log: visible[i],
                      onDelete: () => ref
                          .read(logRepositoryProvider)
                          .delete(visible[i].id),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Добавить запись'),
      ),
    );
  }

  Future<void> _openForm(BuildContext context) async {
    final child = ref.read(selectedChildProvider);
    if (child == null) return;
    final draft = await showDialog<DevelopmentLog>(
      context: context,
      builder: (_) => _LogFormDialog(childId: child.id),
    );
    if (draft != null) {
      await ref.read(logRepositoryProvider).add(draft);
    }
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final LogType? selected;
  final ValueChanged<LogType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Text('Все'),
          selected: selected == null,
          onSelected: (_) => onChanged(null),
        ),
        for (final t in LogType.values)
          FilterChip(
            label: Text(t.label),
            selected: selected == t,
            onSelected: (_) => onChanged(t),
          ),
      ],
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log, required this.onDelete});

  final DevelopmentLog log;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = log.metrics;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          child: Icon(_iconFor(log.type), size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(log.title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                dayMonthYear.format(log.date),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (log.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(log.description, style: theme.textTheme.bodyMedium),
              ],
              if (!metrics.isEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (metrics.weightKg != null)
                      _Pill('${metrics.weightKg} кг'),
                    if (metrics.heightCm != null)
                      _Pill('${metrics.heightCm} см'),
                    if (metrics.headCircumferenceCm != null)
                      _Pill('голова ${metrics.headCircumferenceCm} см'),
                    if (metrics.chestCircumferenceCm != null)
                      _Pill('грудь ${metrics.chestCircumferenceCm} см'),
                  ],
                ),
              ],
              if (log.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [for (final t in log.tags) _Pill('#$t')],
                ),
              ],
            ],
          ),
        ),
        IconButton(
          tooltip: 'Удалить запись',
          onPressed: onDelete,
          icon: const Icon(Icons.close, size: 18),
        ),
      ],
    );
  }

  static IconData _iconFor(LogType type) => switch (type) {
    LogType.milestone => Icons.star_outline,
    LogType.measurement => Icons.straighten,
    LogType.illness => Icons.sick_outlined,
    LogType.note => Icons.notes,
  };
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: theme.textTheme.labelSmall),
    );
  }
}

class _LogFormDialog extends StatefulWidget {
  const _LogFormDialog({required this.childId});

  final String childId;

  @override
  State<_LogFormDialog> createState() => _LogFormDialogState();
}

class _LogFormDialogState extends State<_LogFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _tags = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _head = TextEditingController();

  LogType _type = LogType.note;
  Severity _severity = Severity.mild;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _tags.dispose();
    _weight.dispose();
    _height.dispose();
    _head.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новая запись'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<LogType>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Тип записи'),
                  items: [
                    for (final t in LogType.values)
                      DropdownMenuItem(value: t, child: Text(t.label)),
                  ],
                  onChanged: (t) => setState(() => _type = t ?? LogType.note),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _title,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Заголовок'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Укажите заголовок'
                      : null,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Дата'),
                    child: Text(shortDate.format(_date)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Описание'),
                ),
                if (_type == LogType.measurement) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _numberField(_weight, 'Вес, кг'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _numberField(_height, 'Рост, см'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _numberField(_head, 'Окружность головы, см'),
                ],
                if (_type == LogType.illness) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Severity>(
                    initialValue: _severity,
                    decoration: const InputDecoration(labelText: 'Тяжесть'),
                    items: [
                      for (final s in Severity.values)
                        DropdownMenuItem(value: s, child: Text(s.label)),
                    ],
                    onChanged: (s) =>
                        setState(() => _severity = s ?? Severity.mild),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tags,
                  decoration: const InputDecoration(
                    labelText: 'Теги, через запятую',
                    hintText: 'моторика, речь',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Сохранить')),
      ],
    );
  }

  Widget _numberField(TextEditingController c, String label) {
    return TextFormField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        return double.tryParse(v.replaceAll(',', '.')) == null
            ? 'Введите число'
            : null;
      },
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 18),
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  double? _parse(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.'));

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final log = DevelopmentLog(
      id: '',
      childId: widget.childId,
      date: _date,
      type: _type,
      title: _title.text.trim(),
      description: _description.text.trim(),
      metrics: _type == LogType.measurement
          ? Metrics(
              weightKg: _parse(_weight),
              heightCm: _parse(_height),
              headCircumferenceCm: _parse(_head),
            )
          : const Metrics(),
      tags: _tags.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      severity: _type == LogType.illness ? _severity : null,
    );
    Navigator.of(context).pop(log);
  }
}
