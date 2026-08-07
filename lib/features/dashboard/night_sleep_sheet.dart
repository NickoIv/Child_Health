import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/labels.dart';
import '../../core/theme/app_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../../models/development_log.dart';
import '../../providers.dart';
import '../shared/widgets.dart';

/// The night, recorded in one go.
///
/// A night is not a stretch of sleep; it is a stretch with holes in it, and a
/// parent asked "how did the baby sleep" answers with the whole shape: went
/// down at nine, up twice, fed once, awake at six. Logging that as five
/// separate events at six in the morning is not going to happen.
///
/// Stored as an ordinary [LogType.sleep] entry so every existing count, chart
/// and daily total keeps working — see [DevelopmentLog.nightWakings].
Future<void> showNightSleepSheet(
  BuildContext context, {
  required String childId,
  DevelopmentLog? existing,
}) {
  return showAppSheet<void>(
    context,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _NightSleepSheet(childId: childId, existing: existing),
    ),
  );
}

class _NightSleepSheet extends ConsumerStatefulWidget {
  const _NightSleepSheet({required this.childId, this.existing});

  final String childId;
  final DevelopmentLog? existing;

  @override
  ConsumerState<_NightSleepSheet> createState() => _NightSleepSheetState();
}

class _NightSleepSheetState extends ConsumerState<_NightSleepSheet> {
  late DateTime _asleep;
  late DateTime _awake;
  late int _wakings;
  late int _feeds;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _asleep = existing.date;
      _awake = existing.date.add(
        Duration(minutes: existing.durationMinutes ?? 0),
      );
      _wakings = existing.nightWakings ?? 0;
      _feeds = existing.nightFeeds ?? 0;
      return;
    }

    // Defaults for the usual case: it is morning, the night just ended.
    // Yesterday at 21:00 until now, which is right often enough that many
    // parents will only correct one of the two.
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    _asleep = DateTime(yesterday.year, yesterday.month, yesterday.day, 21);
    _awake = now;
    _wakings = 0;
    _feeds = 0;
  }

  /// Negative when the fields contradict each other, which the button checks.
  int get _minutes => _awake.difference(_asleep).inMinutes;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final valid = _minutes > 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.bedtime_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(l.quickNightSleep, style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            DateTimeField(
              value: _asleep,
              dateLabel: l.nightAsleepDate,
              timeLabel: l.commonTime,
              onChanged: (v) => setState(() => _asleep = v),
            ),
            const SizedBox(height: 12),
            DateTimeField(
              value: _awake,
              dateLabel: l.nightAwakeDate,
              timeLabel: l.commonTime,
              onChanged: (v) => setState(() => _awake = v),
            ),
            const SizedBox(height: 16),
            _Counter(
              icon: Icons.visibility_outlined,
              label: l.nightWokeUp,
              value: _wakings,
              onChanged: (v) => setState(() {
                _wakings = v;
                // Feeds are a subset of wakings; letting them exceed it would
                // record a night that did not happen.
                if (_feeds > _wakings) _feeds = _wakings;
              }),
            ),
            const SizedBox(height: 8),
            _Counter(
              icon: Icons.local_drink_outlined,
              label: l.nightOfThoseFeeds,
              value: _feeds,
              max: _wakings,
              onChanged: (v) => setState(() => _feeds = v),
            ),
            const SizedBox(height: 16),
            Text(
              valid
                  ? l.nightTotal(localizedDuration(l, _minutes))
                  : l.nightInvalid,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: valid
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            // Full width and at the bottom: the one place a thumb reaches
            // without shifting grip, which at six in the morning matters more
            // than it looks.
            FilledButton(
              onPressed: valid && !_saving ? _save : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l.commonSave),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repository = ref.read(logRepositoryProvider);
    final existing = widget.existing;

    final log = DevelopmentLog(
      id: existing?.id ?? '',
      childId: widget.childId,
      // The night is filed under the evening it started, which is where a
      // parent looks for it.
      date: _asleep,
      type: LogType.sleep,
      title: 'Ночной сон',
      durationMinutes: _minutes,
      nightWakings: _wakings,
      nightFeeds: _feeds,
    );

    if (existing == null) {
      await repository.add(log);
    } else {
      await repository.update(log);
    }
    if (mounted) Navigator.of(context).pop();
  }
}

/// Minus, number, plus — big enough to hit half asleep.
class _Counter extends StatelessWidget {
  const _Counter({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.max = 20,
  });

  final IconData icon;
  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
        IconButton.filledTonal(
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 44,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ),
        IconButton.filledTonal(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
