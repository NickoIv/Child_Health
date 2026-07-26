import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/photos/compression.dart';
import '../../models/medical_record.dart';
import '../../providers.dart';
import '../shared/photo_widgets.dart';
import '../shared/widgets.dart';

/// Editable draft of one lab measurement.
///
/// A mutable holder rather than the immutable [LabResult]: the form edits
/// these in place across rebuilds, and rebuilding the model on every
/// keystroke would fight the text controllers.
class _LabDraft {
  _LabDraft();

  final name = TextEditingController();
  final value = TextEditingController();
  final unit = TextEditingController();
  final min = TextEditingController();
  final max = TextEditingController();

  void dispose() {
    name.dispose();
    value.dispose();
    unit.dispose();
    min.dispose();
    max.dispose();
  }

  bool get isBlank =>
      name.text.trim().isEmpty && value.text.trim().isEmpty;

  LabResult? toResult() {
    final parsedValue = _num(value);
    if (name.text.trim().isEmpty || parsedValue == null) return null;
    return LabResult(
      name: name.text.trim(),
      value: parsedValue,
      unit: unit.text.trim(),
      referenceMin: _num(min),
      referenceMax: _num(max),
    );
  }

  static double? _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));
}

/// Form for a doctor's visit: diagnosis, prescriptions, lab results, scans.
class MedicalRecordForm extends ConsumerStatefulWidget {
  const MedicalRecordForm({required this.childId, super.key});

  final String childId;

  @override
  ConsumerState<MedicalRecordForm> createState() => _MedicalRecordFormState();
}

class _MedicalRecordFormState extends ConsumerState<MedicalRecordForm> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosis = TextEditingController();
  final _doctor = TextEditingController();
  final _prescriptions = TextEditingController();
  final _labs = <_LabDraft>[_LabDraft()];
  final _fileIds = <String>[];

  DateTime _date = DateTime.now();
  bool _uploading = false;
  String? _photoError;

  @override
  void dispose() {
    _diagnosis.dispose();
    _doctor.dispose();
    _prescriptions.dispose();
    for (final l in _labs) {
      l.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Медицинская запись'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _diagnosis,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Диагноз или причина визита',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Укажите диагноз или причину визита'
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
                  controller: _doctor,
                  decoration: const InputDecoration(
                    labelText: 'Врач и учреждение',
                    hintText: 'Педиатр, поликлиника №2',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _prescriptions,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Назначения',
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    Text('Анализы', style: theme.textTheme.labelLarge),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => setState(() => _labs.add(_LabDraft())),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Добавить строку'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                for (var i = 0; i < _labs.length; i++)
                  _LabRow(
                    draft: _labs[i],
                    onRemove: _labs.length == 1
                        ? null
                        : () => setState(() => _labs.removeAt(i).dispose()),
                  ),
                Text(
                  'Референсные значения не обязательны, но без них приложение '
                  'не сможет отметить отклонение.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 20),
                _ScanPicker(
                  fileIds: _fileIds,
                  uploading: _uploading,
                  error: _photoError,
                  onAdd: _pickScans,
                  onRemove: _removeScan,
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

  Future<void> _pickScans() async {
    final files = await ImagePicker().pickMultiImage(imageQuality: 90);
    if (files.isEmpty) return;

    setState(() {
      _uploading = true;
      _photoError = null;
    });

    final repository = ref.read(photoRepositoryProvider);
    for (final file in files) {
      try {
        final photo = await repository.upload(
          childId: widget.childId,
          bytes: await file.readAsBytes(),
          caption: 'Скан бланка',
        );
        if (!mounted) return;
        setState(() => _fileIds.add(photo.id));
      } on PhotoTooLargeException catch (e) {
        if (mounted) setState(() => _photoError = e.message);
      } catch (e) {
        if (mounted) setState(() => _photoError = 'Не удалось загрузить: $e');
      }
    }

    if (mounted) setState(() => _uploading = false);
  }

  Future<void> _removeScan(String id) async {
    await ref.read(photoRepositoryProvider).delete(id);
    if (mounted) setState(() => _fileIds.remove(id));
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Half-filled rows are dropped rather than rejected: a parent copying a
    // form off a lab printout will leave the spare row blank, and stopping
    // them with an error there would be pedantry.
    final results = <LabResult>[];
    for (final draft in _labs) {
      if (draft.isBlank) continue;
      final parsed = draft.toResult();
      if (parsed == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Проверьте строку «${draft.name.text.trim()}»: '
              'нужно название и числовое значение.',
            ),
          ),
        );
        return;
      }
      results.add(parsed);
    }

    Navigator.of(context).pop(
      MedicalRecord(
        id: '',
        childId: widget.childId,
        date: _date,
        diagnosis: _diagnosis.text.trim(),
        prescriptions: _prescriptions.text.trim(),
        doctor: _doctor.text.trim(),
        labResults: results,
        files: List.of(_fileIds),
      ),
    );
  }
}

class _LabRow extends StatelessWidget {
  const _LabRow({required this.draft, required this.onRemove});

  final _LabDraft draft;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: draft.name,
              decoration: const InputDecoration(
                labelText: 'Показатель',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: draft.value,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Значение',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: draft.unit,
              decoration: const InputDecoration(
                labelText: 'Ед.',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: draft.min,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'от',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: draft.max,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'до',
                isDense: true,
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Убрать строку',
          ),
        ],
      ),
    );
  }
}

class _ScanPicker extends StatelessWidget {
  const _ScanPicker({
    required this.fileIds,
    required this.uploading,
    required this.error,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> fileIds;
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
            Text('Сканы бланков', style: theme.textTheme.labelLarge),
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
                icon: const Icon(Icons.attach_file, size: 18),
                label: const Text('Прикрепить'),
              ),
          ],
        ),
        if (fileIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in fileIds)
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
