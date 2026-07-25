import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/vaccination/national_calendar.dart';
import '../../models/child.dart';
import '../../providers.dart';
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
        error: (e, _) => Center(child: Text('Ошибка загрузки: $e')),
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

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_ChildDraft>(
      context: context,
      builder: (_) => const _ChildFormDialog(),
    );
    if (result == null) return;
    final created = await ref
        .read(childRepositoryProvider)
        .add(
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
  }
}

class _ChildTile extends StatelessWidget {
  const _ChildTile({
    required this.child,
    required this.isSelected,
    required this.onSelect,
    required this.onDelete,
  });

  final Child child;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: isSelected
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        child: Icon(
          child.gender == Gender.male ? Icons.boy : Icons.girl,
          color: isSelected ? scheme.onPrimaryContainer : scheme.onSurface,
        ),
      ),
      title: Text(child.name),
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
  const _ChildDraft(this.name, this.birthDate, this.gender);

  final String name;
  final DateTime birthDate;
  final Gender gender;
}

class _ChildFormDialog extends StatefulWidget {
  const _ChildFormDialog();

  @override
  State<_ChildFormDialog> createState() => _ChildFormDialogState();
}

class _ChildFormDialogState extends State<_ChildFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _birthDate;
  Gender _gender = Gender.male;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новый профиль'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
        FilledButton(onPressed: _submit, child: const Text('Создать')),
      ],
    );
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
    Navigator.of(
      context,
    ).pop(_ChildDraft(_nameController.text.trim(), _birthDate!, _gender));
  }
}
