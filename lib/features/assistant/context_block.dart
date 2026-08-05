import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/labels.dart';
import '../../core/units/units.dart';
import '../../l10n/app_localizations.dart';
import '../../models/development_log.dart';
import '../../models/json.dart';
import '../../providers.dart';
import '../shared/widgets.dart';

/// What the parent already knows, gathered before she has to say it.
///
/// Sitting down to ask a question about a child usually starts with the same
/// five facts — how old, when she last ate, when she last slept, whether the
/// thermometer came out today — and having to remember them is the tax on
/// asking at all. They are pulled from entries she has already made; nothing
/// here is sent anywhere, and nothing is concluded from it.
class ChildContextBlock extends ConsumerWidget {
  const ChildContextBlock({super.key, this.now});

  /// Injectable so "today" can be pinned in a test.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider);
    if (child == null) return const SizedBox.shrink();

    final moment = now ?? DateTime.now();
    final logs = ref.watch(logsProvider).value ?? const <DevelopmentLog>[];
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    final lastFeeding = _latest(logs, moment, (log) => log.type ==
        LogType.feeding);
    final lastSleep = _latest(
      logs,
      moment,
      (log) => log.type == LogType.sleep && !log.isNightSleep,
    );
    final lastNight = _latest(logs, moment, (log) => log.isNightSleep);
    final temperature = _temperatureToday(logs, moment);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        // Sized by its content wherever it is put, not by whatever height the
        // parent happens to offer.
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.child_care_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l.contextTitle,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                child.name,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // One line per fact, so the block scans in a second and stays short
          // enough on a phone to leave the search field on screen.
          _Line(label: l.commonAge, value: localizedAge(l, child)),
          _Line(
            label: l.nowLastFeeding,
            value: lastFeeding == null
                ? l.nowNothingYet
                : _when(l, lastFeeding.date, moment),
          ),
          _Line(
            label: l.nowLastSleep,
            value: lastSleep == null
                ? l.nowNothingYet
                : _sleep(l, lastSleep),
          ),
          _Line(
            label: l.quickNightSleep,
            value: lastNight?.durationMinutes == null
                ? l.nowNothingYet
                : localizedDuration(l, lastNight!.durationMinutes!),
          ),
          _Line(
            label: l.quickSheetTemperature,
            // Stated as a reading that was or was not taken. What it means is
            // not this block's business.
            value: temperature == null
                ? l.contextNotRecorded
                : Units.formatTemperature(temperature),
          ),
        ],
      ),
    );
  }

  /// The most recent matching entry that has already happened.
  static DevelopmentLog? _latest(
    List<DevelopmentLog> logs,
    DateTime now,
    bool Function(DevelopmentLog) matches,
  ) {
    DevelopmentLog? latest;
    for (final log in logs) {
      if (log.date.isAfter(now) || !matches(log)) continue;
      if (latest == null || log.date.isAfter(latest.date)) latest = log;
    }
    return latest;
  }

  /// The last reading of the current day, if the thermometer came out at all.
  static double? _temperatureToday(List<DevelopmentLog> logs, DateTime now) {
    final today = dateOnly(now);
    DateTime? at;
    double? value;

    for (final log in logs) {
      final t = log.metrics.temperatureC;
      if (t == null || log.date.isAfter(now)) continue;
      if (dateOnly(log.date) != today) continue;
      if (at == null || log.date.isAfter(at)) {
        at = log.date;
        value = t;
      }
    }
    return value;
  }

  /// A clock time and how long ago that was, which is how the question tends
  /// to be asked out loud.
  static String _when(AppLocalizations l, DateTime at, DateTime now) {
    final minutes = now.difference(at).inMinutes;
    final ago = l.nowAgo(localizedDuration(l, minutes < 1 ? 1 : minutes));
    return '${timeOfDay.format(at)} · $ago';
  }

  /// A nap gets its clock time and its length, and not how long ago it was:
  /// three facts on one line wrapped onto two on a phone, and the length is
  /// the part the clock time does not already give away.
  static String _sleep(AppLocalizations l, DevelopmentLog log) {
    final at = timeOfDay.format(log.date);
    final minutes = log.durationMinutes;
    return minutes == null ? at : '$at · ${localizedDuration(l, minutes)}';
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Flexible rather than fixed: "14:20 · 2 ч назад · 1 ч 30 мин" is a
          // long value on a narrow phone, and it wraps rather than clipping.
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
