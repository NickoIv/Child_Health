import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/labels.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
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
    final l = AppLocalizations.of(context);
    final child = ref.watch(selectedChildProvider);
    if (child == null) return const NoChildPlaceholder();

    final remindersAsync = ref.watch(remindersProvider);
    if (remindersAsync.hasError) {
      return PageBody(
        children: [
          SectionCard(
            title: l.navReminders,
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
                l.remindersActiveCount(
                  all.where((r) => !r.isCompleted).length,
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            FilterChip(
              label: Text(AppLocalizations.of(context).remindersShowCompleted),
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
    final brightness = Theme.of(context).brightness;
    return SectionCard(
      title: type.sectionTitle(AppLocalizations.of(context)),
      icon: switch (type) {
        ReminderType.vaccination => Icons.vaccines_outlined,
        ReminderType.medication => Icons.medication_outlined,
        ReminderType.appointment => Icons.event_available_outlined,
      },
      accentColor: switch (type) {
        ReminderType.vaccination => VizPalette.slot(0, brightness),
        ReminderType.medication => VizPalette.slot(2, brightness),
        ReminderType.appointment => VizPalette.slot(6, brightness),
      },
      child: reminders.isEmpty
          ? EmptyState(
              icon: Icons.done_all,
              message: AppLocalizations.of(context).remindersNothingPlanned,
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
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final days = reminder.daysUntil;
    final overdue = reminder.isOverdue;

    final when = switch (days) {
      0 => l.commonToday,
      1 => l.commonTomorrow,
      _ when days < 0 => l.remindersOverdue(-days),
      _ => l.remindersInDays(days),
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
                reminder.type == ReminderType.vaccination
                    ? localizedVaccinationName(l, reminder.title)
                    : reminder.title,
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
                  localizedVaccinationDetails(l, reminder.details),
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
                reminder.recurrence.localizedLabel(
                  AppLocalizations.of(context),
                ),
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
