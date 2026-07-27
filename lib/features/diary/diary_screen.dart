import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/photos/compression.dart';
import '../../core/theme/app_theme.dart';
import '../../core/units/units.dart';
import '../../models/app_user.dart';
import '../../models/development_log.dart';
import '../../providers.dart';
import '../shared/photo_widgets.dart';
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
                message: 'Здесь будет история малыша',
                hint: 'Кормления и подгузники отмечаются кнопками на главной, '
                    'а первое слово и первый зуб — здесь',
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

class _LogTile extends ConsumerWidget {
  const _LogTile({required this.log, required this.onDelete});

  final DevelopmentLog log;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final metrics = log.metrics;
    final units = ref.watch(unitSystemProvider);
    final accent = _colorFor(log.type, theme.brightness);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_iconFor(log.type), size: 18, color: accent),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(log.title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                // Routine entries happen many times a day, so the clock time
                // is the useful part; a milestone only needs the date.
                log.type.isRoutine
                    ? '${dayMonth.format(log.date)}, '
                          '${timeOfDay.format(log.date)}'
                          '${log.routineSummary.isEmpty ? '' : ' · ${log.routineSummary}'}'
                    : dayMonthYear.format(log.date),
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
                    if (metrics.temperatureC != null)
                      _Pill(
                        Units.formatTemperature(metrics.temperatureC!),
                        highlight: metrics.hasFever,
                      ),
                    if (metrics.weightKg != null)
                      _Pill(Units.formatWeight(metrics.weightKg!, units)),
                    if (metrics.heightCm != null)
                      _Pill(Units.formatHeight(metrics.heightCm!, units)),
                    if (metrics.headCircumferenceCm != null)
                      _Pill(
                        'голова '
                        '${Units.formatHeight(metrics.headCircumferenceCm!, units)}',
                      ),
                    if (metrics.chestCircumferenceCm != null)
                      _Pill(
                        'грудь '
                        '${Units.formatHeight(metrics.chestCircumferenceCm!, units)}',
                      ),
                  ],
                ),
              ],
              if (log.photos.isNotEmpty) ...[
                const SizedBox(height: 10),
                PhotoStrip(photoIds: log.photos),
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
    LogType.feeding => Icons.water_drop_outlined,
    LogType.nappy => Icons.child_care_outlined,
    LogType.sleep => Icons.bedtime_outlined,
    LogType.question => Icons.help_outline,
    LogType.note => Icons.notes,
  };

  /// Illness takes the status colour rather than a categorical slot: in a
  /// feed of mostly happy entries, a sick day should read as a state and not
  /// as one more category.
  static Color _colorFor(LogType type, Brightness brightness) =>
      switch (type) {
        LogType.illness => StatusColors.alert,
        LogType.milestone => VizPalette.slot(4, brightness),
        LogType.measurement => VizPalette.slot(0, brightness),
        LogType.feeding => VizPalette.slot(2, brightness),
        LogType.nappy => VizPalette.slot(3, brightness),
        LogType.sleep => VizPalette.slot(5, brightness),
        LogType.question => VizPalette.slot(1, brightness),
        LogType.note => VizPalette.slot(6, brightness),
      };
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.photoIds,
    required this.uploading,
    required this.error,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> photoIds;
  final bool uploading;
  final String? error;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Фотографии', style: theme.textTheme.labelLarge),
            const Spacer(),
            if (uploading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: const Text('Добавить'),
              ),
          ],
        ),
        if (photoIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in photoIds)
                Stack(
                  children: [
                    PhotoThumb(photoId: id, size: 64),
                    Positioned(
                      right: -6,
                      top: -6,
                      child: IconButton(
                        iconSize: 18,
                        tooltip: 'Удалить',
                        onPressed: () => onRemove(id),
                        icon: const Icon(Icons.cancel),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, {this.highlight = false});

  final String text;

  /// Draws attention to a value that matters clinically — a fever reading
  /// should be findable while scrolling, not read.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlight
            ? StatusColors.alert.withValues(alpha: 0.16)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: highlight ? StatusColors.alert : null,
          fontWeight: highlight ? FontWeight.w700 : null,
        ),
      ),
    );
  }
}

class _LogFormDialog extends ConsumerStatefulWidget {
  const _LogFormDialog({required this.childId});

  final String childId;

  @override
  ConsumerState<_LogFormDialog> createState() => _LogFormDialogState();
}

class _LogFormDialogState extends ConsumerState<_LogFormDialog> {
  final _photoIds = <String>[];
  bool _uploading = false;
  String? _photoError;

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _tags = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _head = TextEditingController();
  final _chest = TextEditingController();
  final _temperature = TextEditingController();

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
    _chest.dispose();
    _temperature.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(unitSystemProvider);
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
                    for (final t in LogType.formTypes)
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
                        child: _numberField(
                          _weight,
                          'Вес, ${Units.weightUnit(units)}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _numberField(
                          _height,
                          'Рост, ${Units.heightUnit(units)}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _numberField(
                          _head,
                          'Окружность головы, ${Units.heightUnit(units)}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _numberField(
                          _chest,
                          'Окружность груди, ${Units.heightUnit(units)}',
                        ),
                      ),
                    ],
                  ),
                ],
                if (_type == LogType.illness) ...[
                  const SizedBox(height: 12),
                  _numberField(_temperature, 'Температура, °C'),
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
                const SizedBox(height: 16),
                _PhotoPicker(
                  photoIds: _photoIds,
                  uploading: _uploading,
                  error: _photoError,
                  onAdd: _pickPhotos,
                  onRemove: _removePhoto,
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

  /// Reads a field and converts it to the metric value that gets stored.
  double? _toStorage(
    TextEditingController controller,
    double Function(double, UnitSystem) convert,
    UnitSystem units,
  ) {
    final entered = _parse(controller);
    return entered == null ? null : convert(entered, units);
  }

  /// Uploads immediately on pick rather than on save.
  ///
  /// Compression takes a moment on a large photo, and doing it while the
  /// parent is still typing hides that latency. The cost is an orphaned photo
  /// document if the form is then cancelled — cheap, and cleanable later.
  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 90);
    if (files.isEmpty) return;

    setState(() {
      _uploading = true;
      _photoError = null;
    });

    final repository = ref.read(photoRepositoryProvider);
    for (final file in files) {
      try {
        final bytes = await file.readAsBytes();
        final photo = await repository.upload(
          childId: widget.childId,
          bytes: bytes,
        );
        if (!mounted) return;
        setState(() => _photoIds.add(photo.id));
      } on PhotoTooLargeException catch (e) {
        if (mounted) setState(() => _photoError = e.message);
      } catch (e) {
        if (mounted) {
          setState(() => _photoError = 'Не удалось загрузить фото: $e');
        }
      }
    }

    if (mounted) setState(() => _uploading = false);
  }

  Future<void> _removePhoto(String id) async {
    await ref.read(photoRepositoryProvider).delete(id);
    if (mounted) setState(() => _photoIds.remove(id));
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final units = ref.read(unitSystemProvider);
    final log = DevelopmentLog(
      id: '',
      childId: widget.childId,
      date: _date,
      type: _type,
      title: _title.text.trim(),
      description: _description.text.trim(),
      // Converted to metric on the way in. What the parent typed depends on
      // their unit setting; what gets stored never does.
      metrics: switch (_type) {
        LogType.measurement => Metrics(
          weightKg: _toStorage(_weight, Units.weightToStorage, units),
          heightCm: _toStorage(_height, Units.heightToStorage, units),
          headCircumferenceCm: _toStorage(
            _head,
            Units.heightToStorage,
            units,
          ),
          chestCircumferenceCm: _toStorage(
            _chest,
            Units.heightToStorage,
            units,
          ),
        ),
        LogType.illness => Metrics(temperatureC: _parse(_temperature)),
        _ => const Metrics(),
      },
      photos: List.of(_photoIds),
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
