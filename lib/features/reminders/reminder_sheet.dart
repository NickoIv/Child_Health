import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/labels.dart';
import '../../core/theme/app_sheet.dart';
import '../../core/theme/app_snack.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/reminder.dart';
import '../../providers.dart';
import '../shared/widgets.dart';

/// Writing a reminder down.
///
/// Until this existed the planner could only show reminders the app had
/// generated itself — the vaccination calendar — and a parent who wanted to be
/// reminded of a dose at two in the morning had nowhere to say so. That is the
/// one kind of reminder a newborn actually generates, so the sheet is built
/// around it: the medicine is the default, and the answer to "when" is a row
/// of hours rather than a date picker.
///
/// A vaccination is not offered as a type. Those come from the national
/// calendar with the right dates already on them, and a hand-typed duplicate
/// beside a generated one is worse than no entry at all.
Future<void> showReminderSheet(
  BuildContext context, {
  required String childId,
  Reminder? existing,
}) {
  return showAppSheet<void>(
    context,
    builder: (sheetContext) => Padding(
      // Lifts the name field clear of the keyboard. Measured from the sheet's
      // own context: reading the caller's as it is torn down throws while the
      // sheet animates out.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _ReminderSheet(childId: childId, existing: existing),
    ),
  );
}

/// The name field, named so a test can reach it past whatever the screen
/// behind the sheet happens to own.
const reminderNameFieldKey = Key('reminder-name');

/// The offsets offered before the clock. Four, six and eight hours are the
/// intervals paediatric doses actually come at; anything else is a time she
/// can pick.
const _quickHours = [4, 6, 8];

class _ReminderSheet extends ConsumerStatefulWidget {
  const _ReminderSheet({required this.childId, this.existing});

  final String childId;
  final Reminder? existing;

  @override
  ConsumerState<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends ConsumerState<_ReminderSheet> {
  late ReminderType _type = widget.existing?.type ?? ReminderType.medication;
  late Recurrence _repeat = widget.existing?.recurrence ?? Recurrence.none;
  late DateTime _at =
      widget.existing?.scheduledTime ??
      DateTime.now().add(Duration(hours: _quickHours.first));
  late final _name = TextEditingController(text: widget.existing?.title ?? '');

  /// True once she has opened the clock, after which the hour chips would be
  /// lying about what is selected.
  bool _exact = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Which hour chip, if any, the current time still matches. Compared with a
  /// minute of slack: the sheet takes longer than a moment to fill in.
  int? get _selectedOffset {
    if (_exact) return null;
    final ahead = _at.difference(DateTime.now()).inMinutes;
    for (final h in _quickHours) {
      if ((ahead - h * 60).abs() <= 1) return h;
    }
    return null;
  }

  bool get _isTomorrowMorning {
    if (_exact) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return _at.hour == 9 &&
        _at.minute == 0 &&
        _at.day == tomorrow.day &&
        _at.month == tomorrow.month;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    // The form scrolls; «Сохранить» does not.
    //
    // It used to be the last widget in the scrolling column, and on his phone
    // that put it half off the bottom of the screen — the one button the sheet
    // exists for, cut in two, with nothing on screen to say it could be
    // scrolled to. A [Flexible] scroll view over a pinned footer is the fix:
    // whatever the form's height turns out to be in whichever language, the
    // action is whole and in the same place.
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notifications_outlined, color: Warm.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.existing == null
                              ? l.reminderNew
                              : l.reminderTypeMedication,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  SectionLabel(text: l.reminderWhat),
                  Row(
                    children: [
                      for (final type in const [
                        ReminderType.medication,
                        ReminderType.appointment,
                      ]) ...[
                        if (type != ReminderType.medication)
                          const SizedBox(width: 10),
                        Expanded(
                          child: _Choice(
                            label: type.localizedLabel(l),
                            icon: type == ReminderType.medication
                                ? Icons.medication_outlined
                                : Icons.event_available_outlined,
                            selected: _type == type,
                            onTap: () => setState(() => _type = type),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    key: reminderNameFieldKey,
                    controller: _name,
                    autofocus: widget.existing == null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: _type == ReminderType.medication
                          ? l.reminderNameMedication
                          : l.reminderNameAppointment,
                      errorText: _error,
                    ),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                  ),
                  const SizedBox(height: 18),

                  SectionLabel(text: l.reminderWhen),
                  // The answer to "when" for a dose is nearly always a number of
                  // hours from now, and a date picker asks for a year to get it.
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final h in _quickHours)
                        ChoicePill(
                          label: l.reminderInHours(h),
                          selected: _selectedOffset == h,
                          onTap: () => setState(() {
                            _exact = false;
                            _at = DateTime.now().add(Duration(hours: h));
                          }),
                        ),
                      ChoicePill(
                        label: l.reminderTomorrowMorning,
                        selected: _isTomorrowMorning,
                        onTap: () => setState(() {
                          _exact = false;
                          final t = DateTime.now().add(const Duration(days: 1));
                          _at = DateTime(t.year, t.month, t.day, 9);
                        }),
                      ),
                      ChoicePill(
                        label: l.reminderExactTime,
                        selected: _exact,
                        onTap: () => setState(() => _exact = true),
                      ),
                    ],
                  ),
                  if (_exact) ...[
                    const SizedBox(height: 12),
                    DateTimeField(
                      value: _at,
                      future: true,
                      onChanged: (v) => setState(() => _at = v),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    Text(
                      '${dayMonth.format(_at)}, ${timeOfDay.format(_at)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Warm.onCardSoft(theme.brightness),
                        fontWeight: FontWeight.w600,
                        fontFeatures: AppTheme.tabular,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),

                  SectionLabel(text: l.reminderRepeat),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in Recurrence.values)
                        ChoicePill(
                          label: r.localizedLabel(l),
                          selected: _repeat == r,
                          onTap: () => setState(() => _repeat = r),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // The footer. Its own hairline, so that when the form above is long
          // enough to scroll the button reads as sitting over it rather than
          // as the next thing in the list.
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Warm.hairline(theme.brightness)),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(l.commonSave),
                  ),
                  if (widget.existing != null) ...[
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: _saving ? null : _delete,
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(l.reminderDelete),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final title = _name.text.trim();
    if (title.isEmpty) {
      setState(() => _error = l.reminderNameRequired);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final repository = ref.read(reminderRepositoryProvider);
    final when = '${dayMonth.format(_at)}, ${timeOfDay.format(_at)}';
    setState(() => _saving = true);

    try {
      final existing = widget.existing;
      if (existing == null) {
        await repository.add(
          Reminder(
            // Storage assigns the real one; this only has to be non-empty.
            id: '',
            childId: widget.childId,
            type: _type,
            title: title,
            scheduledTime: _at,
            recurrence: _repeat,
          ),
        );
      } else {
        await repository.update(
          existing.copyWith(
            type: _type,
            title: title,
            scheduledTime: _at,
            recurrence: _repeat,
            // Editing a reminder that was already ticked off is how a parent
            // moves a missed dose to a new time, so it comes back.
            isCompleted: false,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        appSnack(friendlyError(l, e), kind: SnackKind.problem),
      );
      return;
    }

    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      appSnack(l.reminderSaved(when), kind: SnackKind.done),
    );
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);

    try {
      await ref.read(reminderRepositoryProvider).delete(widget.existing!.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        appSnack(friendlyError(l, e), kind: SnackKind.problem),
      );
      return;
    }

    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(appSnack(l.reminderDeleted, kind: SnackKind.done));
  }
}

/// One of the two kinds, as a card rather than a chip.
///
/// This is the first choice on the sheet and it is made with a thumb while
/// holding a child; a 32px chip is the wrong target for that.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = selected ? Warm.accent : Warm.onCardSoft(theme.brightness);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Warm.cardRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? Warm.accent.withValues(alpha: 0.10)
              : Warm.soft(theme.brightness),
          borderRadius: BorderRadius.circular(Warm.cardRadius),
          border: Border.all(
            color: selected ? Warm.accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: ink),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  height: 1.15,
                  color: selected ? Warm.accent : Warm.onCard(theme.brightness),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
