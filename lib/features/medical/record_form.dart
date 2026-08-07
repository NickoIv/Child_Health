import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_snack.dart';
import '../../core/l10n/labels.dart';
import '../../l10n/app_localizations.dart';
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
  const MedicalRecordForm({required this.childId, this.existing, super.key});

  final String childId;

  /// When set, the form edits this record instead of creating a new one.
  /// The returned record carries the same id, so the caller updates rather
  /// than inserting a duplicate.
  final MedicalRecord? existing;

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
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing == null) return;

    _diagnosis.text = existing.diagnosis;
    _doctor.text = existing.doctor;
    _prescriptions.text = existing.prescriptions;
    _date = existing.date;
    _fileIds.addAll(existing.files);

    if (existing.labResults.isNotEmpty) {
      // Replace the single blank starter row with the saved results, plus one
      // empty row so another can be added without hunting for a button.
      _labs.first.dispose();
      _labs.clear();
      for (final result in existing.labResults) {
        final draft = _LabDraft()
          ..name.text = result.name
          ..value.text = _trim(result.value)
          ..unit.text = result.unit;
        if (result.referenceMin != null) {
          draft.min.text = _trim(result.referenceMin!);
        }
        if (result.referenceMax != null) {
          draft.max.text = _trim(result.referenceMax!);
        }
        _labs.add(draft);
      }
      _labs.add(_LabDraft());
    }
  }

  /// 9.0 reads better as "9" in an input field the parent is about to edit.
  static String _trim(double value) =>
      value == value.roundToDouble()
          ? value.toStringAsFixed(0)
          : value.toString();

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
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        widget.existing == null ? l.medicalRecordTitle : l.diaryEditEntry,
      ),
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
                  decoration: InputDecoration(
                    labelText: l.medicalDiagnosis,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l.medicalDiagnosisRequired
                      : null,
                ),
                const SizedBox(height: 12),
                DateTimeField(
                  value: _date,
                  onChanged: (v) => setState(() => _date = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _doctor,
                  decoration: InputDecoration(
                    labelText: l.medicalDoctor,
                    hintText: l.medicalDoctorHint,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _prescriptions,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l.medicalPrescriptions,
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(l.medicalLabs, style: theme.textTheme.labelLarge),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => setState(() => _labs.add(_LabDraft())),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l.medicalAddRow),
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
                  l.medicalReferenceHint,
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
          child: Text(l.commonCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l.commonSave)),
      ],
    );
  }

  Future<void> _pickScans() async {
    // Read before the picker: it hands control to the system UI, and after
    // that this context may no longer be mounted.
    final l = AppLocalizations.of(context);
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
          caption: l.medicalScan,
        );
        if (!mounted) return;
        setState(() => _fileIds.add(photo.id));
      } on PhotoTooLargeException catch (e) {
        if (mounted) {
          setState(
            () => _photoError = photoProblemText(l, e.problem),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(
            () => _photoError = l.medicalUploadFailed('$e'),
          );
        }
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
          appSnack(
            AppLocalizations.of(
              context,
            ).medicalRowInvalid(draft.name.text.trim()),
            kind: SnackKind.problem,
          ),
        );
        return;
      }
      results.add(parsed);
    }

    Navigator.of(context).pop(
      MedicalRecord(
        // Keeping the id is what makes this an edit rather than a copy.
        id: widget.existing?.id ?? '',
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
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: draft.name,
              decoration: InputDecoration(
                labelText: l.medicalIndicator,
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
              decoration: InputDecoration(
                labelText: l.medicalValue,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: draft.unit,
              decoration: InputDecoration(
                labelText: l.medicalUnitShort,
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
              decoration: InputDecoration(
                labelText: l.medicalFrom,
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
              decoration: InputDecoration(
                labelText: l.medicalTo,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 18),
            tooltip: l.medicalRemoveRow,
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
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(l.medicalScans, style: theme.textTheme.labelLarge),
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
                label: Text(l.medicalAttach),
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
                        tooltip: l.commonDelete,
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
