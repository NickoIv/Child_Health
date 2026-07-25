import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/reminder.dart';
import '../../providers.dart';
import '../shared/widgets.dart';

/// Planner: vaccination schedule, medication and appointments, per 2.6.
class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(selectedChildProvider);
    if (child == null) return const NoChildPlaceholder();

    final remindersAsync = ref.watch(remindersProvider);
    if (remindersAsync.hasError) {
      return PageBody(
        children: [
          SectionCard(
            title: 'Напоминания',
            icon: Icons.notifications_outlined,
            child: ErrorState(
              error: remindersAsync.error!,
              onRetry: () => ref.invalidate(remindersProvider),
            ),
          ),
        ],
      );
    }

    final all = remindersAsync.value ?? const <Reminder>[];
    final visible = _showCompleted
        ? all
        : all.where((r) => !r.isCompleted).toList();

    return PageBody(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                plural(
                  all.where((r) => !r.isCompleted).length,
                  'активное напоминание',
                  'активных напоминания',
                  'активных напоминаний',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            FilterChip(
              label: const Text('Показать выполненные'),
              selected: _showCompleted,
              onSelected: (v) => setState(() => _showCompleted = v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final type in ReminderType.values) ...[
          _TypeSection(
            type: type,
            reminders: visible.where((r) => r.type == type).toList(),
            onToggle: (r) => ref
                .read(reminderRepositoryProvider)
                .update(r.copyWith(isCompleted: !r.isCompleted)),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _TypeSection extends StatelessWidget {
  const _TypeSection({
    required this.type,
    required this.reminders,
    required this.onToggle,
  });

  final ReminderType type;
  final List<Reminder> reminders;
  final ValueChanged<Reminder> onToggle;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: switch (type) {
        ReminderType.vaccination => 'Календарь прививок',
        ReminderType.medication => 'Приём лекарств',
        ReminderType.appointment => 'Визиты к врачу',
      },
      icon: switch (type) {
        ReminderType.vaccination => Icons.vaccines_outlined,
        ReminderType.medication => Icons.medication_outlined,
        ReminderType.appointment => Icons.event_available_outlined,
      },
      child: reminders.isEmpty
          ? const EmptyState(
              icon: Icons.done_all,
              message: 'Ничего не запланировано',
            )
          : Column(
              children: [
                for (var i = 0; i < reminders.length; i++) ...[
                  if (i > 0) const Divider(height: 16),
                  _ReminderRow(
                    reminder: reminders[i],
                    onToggle: () => onToggle(reminders[i]),
                  ),
                ],
              ],
            ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({required this.reminder, required this.onToggle});

  final Reminder reminder;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = reminder.daysUntil;
    final overdue = reminder.isOverdue;

    final when = switch (days) {
      0 => 'сегодня',
      1 => 'завтра',
      _ when days < 0 => 'просрочено на ${plural(-days, 'день', 'дня', 'дней')}',
      _ => 'через ${plural(days, 'день', 'дня', 'дней')}',
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: reminder.isCompleted,
          onChanged: (_) => onToggle(),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reminder.title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  decoration: reminder.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  color: reminder.isCompleted
                      ? theme.colorScheme.onSurfaceVariant
                      : null,
                ),
              ),
              if (reminder.details.isNotEmpty)
                Text(
                  reminder.details,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              shortDate.format(reminder.scheduledTime),
              style: theme.textTheme.labelMedium,
            ),
            if (!reminder.isCompleted)
              Text(
                when,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: overdue
                      ? StatusColors.alert
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (reminder.recurrence != Recurrence.none)
              Text(
                reminder.recurrence.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
