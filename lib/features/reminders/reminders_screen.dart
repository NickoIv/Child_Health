import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/labels.dart';
import '../../core/theme/app_snack.dart';
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

  /// Ticking one off, with a way back.
  ///
  /// A completed reminder leaves the list — that is the point of the list —
  /// but until now it left in silence, and a tick landed on by accident was
  /// indistinguishable from a reminder that had vanished. He reported exactly
  /// that: «нажал на напоминание, и оно исчезло». So the row says what it
  /// did and offers to undo it, which is also the honest answer when the tap
  /// was meant for the title beside it.
  Future<void> _toggle(Reminder reminder) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(reminderRepositoryProvider);
    final done = !reminder.isCompleted;

    await repository.update(reminder.copyWith(isCompleted: done));
    if (!mounted) return;

    // Only the direction that hides something needs explaining; bringing one
    // back is its own confirmation, because the row reappears.
    if (!done) return;

    messenger.showSnackBar(
      appSnack(
        l.reminderCompleted,
        kind: SnackKind.done,
        action: SnackBarAction(
          label: l.commonUndo,
          onPressed: () =>
              repository.update(reminder.copyWith(isCompleted: false)),
        ),
      ),
    );
  }

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

    // No floating button any more. It asked «напоминание о чём?» on the sheet
    // as its first question, when the answer was already on the screen behind
    // it: a parent who wants a dose at two in the morning is looking at
    // «Приём лекарств» when she decides. The add now lives in each section's
    // own header and arrives with the type already chosen — «так удобнее».
    return Scaffold(
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
              ChoicePill(
                label: l.remindersShowCompleted,
                icon: Icons.done_all,
                selected: _showCompleted,
                onTap: () => setState(() => _showCompleted = !_showCompleted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final type in ReminderType.values) ...[
            _TypeSection(
              type: type,
              reminders: visible.where((r) => r.type == type).toList(),
              onToggle: _toggle,
              // A generated vaccination is the calendar's to move, not a
              // parent's; the two she wrote herself open for editing.
              onOpen: type == ReminderType.vaccination
                  ? null
                  : (r) => showReminderSheet(
                      context,
                      childId: child.id,
                      existing: r,
                    ),
              // And the same rule decides who may add one: a hand-typed
              // vaccination beside a generated one is worse than no entry.
              onAdd: type == ReminderType.vaccination
                  ? null
                  : () => showReminderSheet(
                      context,
                      childId: child.id,
                      initialType: type,
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
    this.onAdd,
  });

  final ReminderType type;
  final List<Reminder> reminders;
  final ValueChanged<Reminder> onToggle;

  /// Opens the reminder for editing. Null for the generated vaccinations,
  /// which belong to the national calendar rather than to a parent.
  final ValueChanged<Reminder>? onOpen;

  /// Writes a new one of this kind. Null on the vaccination section, where
  /// the national calendar is the only author.
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final brightness = Theme.of(context).brightness;
    return SectionCard(
      title: type.sectionTitle(l),
      icon: switch (type) {
        ReminderType.vaccination => Icons.vaccines_outlined,
        ReminderType.medication => Icons.medication_outlined,
        ReminderType.appointment => Icons.event_available_outlined,
      },
      // The heading is where the decision is made, so it is where the button
      // goes — on the same line as the section it will write into.
      action: onAdd == null
          ? null
          : TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l.commonAdd),
            ),
      accentColor: switch (type) {
        ReminderType.vaccination => VizPalette.slot(0, brightness),
        ReminderType.medication => VizPalette.slot(2, brightness),
        ReminderType.appointment => VizPalette.slot(6, brightness),
      },
      child: reminders.isEmpty
          ? EmptyState(
              icon: Icons.done_all,
              message: l.remindersNothingPlanned,
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

    // The row opens for editing, the box ticks it off — and the box is the
    // one that makes the row disappear, so it gets room around it. Twelve
    // pixels rather than four: the Checkbox already claims a 48px tap target
    // of its own, and the gap is what keeps a thumb aimed at the first letters
    // of the title from landing on the edge of it.
    //
    // The width is deliberately not constrained. Boxing the Checkbox into
    // anything under 48 makes its hit area overflow the box, and taps start
    // missing it altogether — which the test below caught the first time.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: reminder.isCompleted,
          onChanged: (_) => onToggle(),
        ),
        const SizedBox(width: 12),
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
