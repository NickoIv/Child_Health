import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/glass.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/reminder.dart';
import '../../providers.dart';
import '../shared/widgets.dart';
import 'reminder_sheet.dart';

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

    return Scaffold(
      // The planner could only ever show what the app had generated itself.
      // This is the button that lets a parent add the reminder she actually
      // needs — a dose in four hours — and it is the reason the screen exists
      // rather than being a read-only calendar.
      floatingActionButton: liftedFab(
        context,
        FloatingActionButton.extended(
          onPressed: () => showReminderSheet(context, childId: child.id),
          icon: const Icon(Icons.add_alert_outlined),
          label: Text(l.reminderAdd),
        ),
      ),
      body: PageBody(
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
                label: Text(l.remindersShowCompleted),
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
              // A generated vaccination is the calendar's to move, not a
              // parent's; the two she wrote herself open for editing.
              onOpen: type == ReminderType.vaccination
                  ? null
                  : (r) => showReminderSheet(
                      context,
                      childId: child.id,
                      existing: r,
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _TypeSection extends StatelessWidget {
  const _TypeSection({
    required this.type,
    required this.reminders,
    required this.onToggle,
    this.onOpen,
  });

  final ReminderType type;
  final List<Reminder> reminders;
  final ValueChanged<Reminder> onToggle;

  /// Opens the reminder for editing. Null for the generated vaccinations,
  /// which belong to the national calendar rather than to a parent.
  final ValueChanged<Reminder>? onOpen;

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
                    onOpen: onOpen == null
                        ? null
                        : () => onOpen!(reminders[i]),
                  ),
                ],
              ],
            ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.reminder,
    required this.onToggle,
    this.onOpen,
  });

  final Reminder reminder;
  final VoidCallback onToggle;
  final VoidCallback? onOpen;

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

    // The row opens for editing, the box ticks it off. Two targets on one
    // line, and the smaller of them is the one that changes nothing.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: reminder.isCompleted,
          onChanged: (_) => onToggle(),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(Warm.chipRadius),
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
