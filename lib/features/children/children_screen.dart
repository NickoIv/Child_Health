import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/photos/compression.dart';
import '../../core/vaccination/national_calendar.dart';
import '../../models/child.dart';
import '../../providers.dart';
import '../shared/photo_widgets.dart';
import '../shared/widgets.dart';

class ChildrenScreen extends ConsumerWidget {
  const ChildrenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(childrenProvider);
    final selected = ref.watch(selectedChildProvider);

    return Scaffold(
      body: children.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => PageBody(
          children: [
            SectionCard(
              title: 'Профили детей',
              icon: Icons.family_restroom_outlined,
              child: ErrorState(
                error: e,
                onRetry: () => ref.invalidate(childrenProvider),
              ),
            ),
          ],
        ),
        data: (list) => PageBody(
          children: [
            if (list.isEmpty)
              const SectionCard(
                title: 'Профили детей',
                icon: Icons.family_restroom_outlined,
                child: EmptyState(
                  icon: Icons.child_care_outlined,
                  message: 'Пока нет ни одного профиля',
                  hint: 'Нажмите «Добавить ребёнка», чтобы начать',
                ),
              )
            else
              SectionCard(
                title: 'Профили детей',
                icon: Icons.family_restroom_outlined,
                child: Column(
                  children: [
                    for (final c in list)
                      _ChildTile(
                        child: c,
                        isSelected: c.id == selected?.id,
                        onSelect: () => ref
                            .read(selectedChildIdProvider.notifier)
                            .select(c.id),
                        onEdit: () => editChildFlow(context, ref, c),
                        onDelete: () => _confirmDelete(context, ref, c),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Добавить ребёнка'),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Child child,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить профиль?'),
        content: Text(
          'Профиль «${child.name}» будет удалён вместе со всеми записями '
          'дневника, измерениями, медицинскими записями и напоминаниями. '
          'Действие необратимо.',
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
      await ref.read(childRepositoryProvider).delete(child.id);
      ref.read(selectedChildIdProvider.notifier).select(null);
    }
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref) =>
      addChildFlow(context, ref);
}

/// Creates a child profile, from wherever the parent happened to be.
///
/// Public because the empty-state placeholder offers it too: telling someone
/// "open the Children section and add a profile" while showing no button is a
/// dead end, and it is the very first screen a new user meets.
Future<void> addChildFlow(BuildContext context, WidgetRef ref) async {
  final result = await showDialog<_ChildDraft>(
    context: context,
    builder: (_) => const _ChildFormDialog(),
  );
  if (result == null) return;

  final repository = ref.read(childRepositoryProvider);
  final created = await repository.add(
    parentUid: ref.read(currentUidProvider),
    name: result.name,
    birthDate: result.birthDate,
    gender: result.gender,
  );

  // Requirement 2.6: the immunisation plan is generated automatically from
  // the national schedule as soon as a profile exists.
  final reminders = ref.read(reminderRepositoryProvider);
  for (final dose in buildVaccinationPlan(created)) {
    await reminders.add(dose);
  }

  ref.read(selectedChildIdProvider.notifier).select(created.id);

  // Last, and allowed to fail: a photo that will not compress must not cost
  // the parent the profile they just filled in.
  if (result.photoBytes != null && context.mounted) {
    await _attachPhoto(context, ref, created, result.photoBytes!);
  }
}

/// Edits an existing profile — name, date, sex and photo.
Future<void> editChildFlow(
  BuildContext context,
  WidgetRef ref,
  Child child,
) async {
  final result = await showDialog<_ChildDraft>(
    context: context,
    builder: (_) => _ChildFormDialog(existing: child),
  );
  if (result == null) return;

  final updated = child.copyWith(
    name: result.name,
    birthDate: result.birthDate,
    gender: result.gender,
  );
  await ref.read(childRepositoryProvider).update(updated);

  if (result.photoBytes != null && context.mounted) {
    await _attachPhoto(context, ref, updated, result.photoBytes!);
  }
}

/// Uploads the picked image and points the profile at it.
///
/// The previous photo is deleted afterwards rather than before: if the upload
/// fails, the child keeps the face they had.
Future<void> _attachPhoto(
  BuildContext context,
  WidgetRef ref,
  Child child,
  Uint8List bytes,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final photos = ref.read(photoRepositoryProvider);
  final previous = child.photoUrl;

  try {
    final photo = await photos.upload(childId: child.id, bytes: bytes);
    await ref
        .read(childRepositoryProvider)
        .update(child.copyWith(photoUrl: photo.id));
    if (previous != null && previous.isNotEmpty) {
      await photos.delete(previous);
    }
  } on PhotoTooLargeException catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text(e.message)));
  } catch (e) {
    messenger?.showSnackBar(
      SnackBar(content: Text('Не удалось сохранить фото: $e')),
    );
  }
}

class _ChildTile extends StatelessWidget {
  const _ChildTile({
    required this.child,
    required this.isSelected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final Child child;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      selected: isSelected,
      selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.35),
      leading: ChildAvatar(child: child),
      title: Text(child.name, style: theme.textTheme.titleSmall),
      subtitle: Text(
        '${child.ageLabel} · ${shortDate.format(child.birthDate)} · '
        '${child.gender.label.toLowerCase()}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected)
            Chip(
              label: const Text('Выбран'),
              visualDensity: VisualDensity.compact,
              backgroundColor: scheme.primaryContainer,
              side: BorderSide.none,
            ),
          IconButton(
            tooltip: 'Изменить',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Удалить',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      onTap: onSelect,
    );
  }
}

class _ChildDraft {
  const _ChildDraft(this.name, this.birthDate, this.gender, this.photoBytes);

  final String name;
  final DateTime birthDate;
  final Gender gender;

  /// Raw bytes, not an uploaded id: at creation time there is no child to
  /// attach a photo to yet, so the upload waits until the profile exists.
  final Uint8List? photoBytes;
}

class _ChildFormDialog extends StatefulWidget {
  const _ChildFormDialog({this.existing});

  final Child? existing;

  @override
  State<_ChildFormDialog> createState() => _ChildFormDialogState();
}

class _ChildFormDialogState extends State<_ChildFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _birthDate;
  Gender _gender = Gender.male;
  Uint8List? _photoBytes;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name;
      _birthDate = existing.birthDate;
      _gender = existing.gender;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;

    return AlertDialog(
      title: Text(editing ? 'Профиль ребёнка' : 'Новый профиль'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PhotoField(
                bytes: _photoBytes,
                existing: widget.existing,
                onPick: _pickPhoto,
                onClear: _photoBytes == null
                    ? null
                    : () => setState(() => _photoBytes = null),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Имя'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Укажите имя'
                    : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Дата рождения',
                  ),
                  child: Text(
                    _birthDate == null
                        ? 'Выберите дату'
                        : shortDate.format(_birthDate!),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<Gender>(
                segments: [
                  for (final g in Gender.values)
                    ButtonSegment(value: g, label: Text(g.label)),
                ],
                selected: {_gender},
                onSelectionChanged: (s) => setState(() => _gender = s.first),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(editing ? 'Сохранить' : 'Создать'),
        ),
      ],
    );
  }

  Future<void> _pickPhoto() async {
    // Downscaled by the picker before it ever reaches us: a modern phone
    // camera produces 4000px frames, and the compressor would only throw
    // that detail away again after decoding the whole thing.
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1200,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) setState(() => _photoBytes = bytes);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? now,
      firstDate: DateTime(now.year - 18),
      lastDate: now,
      helpText: 'Дата рождения',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите дату рождения')),
      );
      return;
    }
    Navigator.of(context).pop(
      _ChildDraft(
        _nameController.text.trim(),
        _birthDate!,
        _gender,
        _photoBytes,
      ),
    );
  }
}

/// Tappable avatar at the top of the profile form.
class _PhotoField extends StatelessWidget {
  const _PhotoField({
    required this.bytes,
    required this.existing,
    required this.onPick,
    this.onClear,
  });

  final Uint8List? bytes;
  final Child? existing;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const size = 96.0;

    return Column(
      children: [
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(size / 3),
          child: Stack(
            children: [
              if (bytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(size / 3),
                  child: Image.memory(
                    bytes!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                  ),
                )
              else if (existing != null)
                ChildAvatar(child: existing!, size: size)
              else
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(size / 3),
                  ),
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_camera_outlined,
                    size: 15,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onClear ?? onPick,
          child: Text(onClear != null ? 'Убрать фото' : 'Добавить фото'),
        ),
      ],
    );
  }
}
