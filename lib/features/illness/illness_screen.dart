import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/glass.dart';
import '../../core/theme/motion.dart';
import '../../l10n/app_localizations.dart';
import '../../core/l10n/labels.dart';
import '../../core/analytics/illness_stats.dart';
import '../../core/theme/app_theme.dart';
import '../../models/development_log.dart';
import '../../models/json.dart';
import '../../providers.dart';
import '../diary/diary_screen.dart';
import '../shared/widgets.dart';

/// Illness tracking: statistics and the calendar heat map, per 2.4.
class IllnessScreen extends ConsumerWidget {
  const IllnessScreen({super.key});

  static const _monthsShown = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final child = ref.watch(selectedChildProvider);
    if (child == null) return const NoChildPlaceholder();

    final logs = ref.watch(logsProvider).value ?? const <DevelopmentLog>[];
    final illnessLogs = logs.where((l) => l.type == LogType.illness).toList();
    final sickDays = ref.watch(illnessDaysProvider);

    return Scaffold(
      // The screen a parent opens on the day a child is ill had nothing on it
      // to press. The empty state pointed at the diary, which is a screen away
      // and asks for a type first — a detour taken while holding a hot child.
      floatingActionButton: liftedFab(
        context,
        FloatingActionButton.extended(
          onPressed: () => showDiaryEntryForm(
            context,
            ref,
            childId: child.id,
            initialType: LogType.illness,
          ),
          icon: const Icon(Icons.add),
          label: Text(l.illnessAdd),
        ),
      ),
      body: PageBody(
        children: [
        SectionCard(
          title: l.illnessTitle,
          icon: Icons.thermostat_outlined,
          child: _Stats(
            sickDays: sickDays,
            episodes: countIllnessEpisodes(sickDays),
            logs: illnessLogs,
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l.illnessHeatmap(_monthsShown),
          icon: Icons.calendar_month_outlined,
          child: _HeatMap(
            severityByDay: ref.watch(illnessSeverityByDayProvider),
            months: _monthsShown,
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l.illnessEpisodes,
          icon: Icons.list_alt_outlined,
          child: illnessLogs.isEmpty
              ? EmptyState(
                  icon: Icons.sentiment_satisfied_outlined,
                  message: l.illnessEmpty,
                  hint: l.illnessEmptyHint,
                )
              : Column(
                  children: [
                    for (var i = 0; i < illnessLogs.length; i++) ...[
                      if (i > 0) const Divider(height: 20),
                      // Keyed by the entry's own id: a temperature just taken
                      // rises into the list, and the ones above it hold still.
                      Arrival(
                        key: ValueKey(illnessLogs[i].id),
                        child: _IllnessRow(log: illnessLogs[i]),
                      ),
                    ],
                  ],
                ),
          ),
        ],
      ),
    );
  }

}

class _Stats extends StatelessWidget {
  const _Stats({
    required this.sickDays,
    required this.episodes,
    required this.logs,
  });

  final Set<DateTime> sickDays;
  final int episodes;
  final List<DevelopmentLog> logs;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final lastYear = sickDays
        .where((d) => now.difference(d).inDays <= 365)
        .length;
    final lastQuarter = sickDays
        .where((d) => now.difference(d).inDays <= 90)
        .length;

    return Wrap(
      spacing: 36,
      runSpacing: 18,
      children: [
        StatTile(
          value: sickDays.length.toString(),
          caption: l.illnessDaysTotal,
          color: sickDays.isEmpty ? StatusColors.normal : null,
        ),
        StatTile(value: episodes.toString(), caption: l.illnessEpisodesCount),
        StatTile(value: lastYear.toString(), caption: l.illnessDays12),
        StatTile(value: lastQuarter.toString(), caption: l.illnessDays3),
      ],
    );
  }
}

/// GitHub-style calendar: one square per day, coloured when the child was ill.
class _HeatMap extends StatelessWidget {
  const _HeatMap({required this.severityByDay, required this.months});

  final Map<DateTime, Severity> severityByDay;
  final int months;

  /// Colour by how bad the day was, not merely whether it counted. A week of
  /// a runny nose and a week of high fever are different histories, and the
  /// point of a heat map is to make that visible without reading anything.
  static Color _colorFor(Severity? severity, ThemeData theme) =>
      switch (severity) {
        null => Warm.soft(theme.brightness),
        Severity.mild => StatusColors.warning,
        Severity.moderate => StatusColors.serious,
        Severity.severe => StatusColors.alert,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final today = dateOnly(DateTime.now());
    final start = DateTime(today.year, today.month - months + 1);

    final weeks = <List<DateTime?>>[];
    var cursor = start.subtract(Duration(days: start.weekday - 1));
    while (cursor.isBefore(today) || cursor.isAtSameMomentAs(today)) {
      final week = <DateTime?>[];
      for (var i = 0; i < 7; i++) {
        final day = cursor.add(Duration(days: i));
        week.add(day.isAfter(today) || day.isBefore(start) ? null : day);
      }
      weeks.add(week);
      cursor = cursor.add(const Duration(days: 7));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final week in weeks)
                Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Column(
                    children: [
                      for (final day in week)
                        Tooltip(
                          message: day == null
                              ? ''
                              : severityByDay[day] == null
                              ? l.illnessDayWell(shortDate.format(day))
                              : '${shortDate.format(day)} — '
                                    '${severityByDay[day]!.localizedLabel(l).toLowerCase()}',
                          child: Container(
                            width: 13,
                            height: 13,
                            margin: const EdgeInsets.only(bottom: 3),
                            decoration: BoxDecoration(
                              color: day == null
                                  ? Colors.transparent
                                  : _colorFor(severityByDay[day], theme),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Every swatch is labelled: the severity ramp must not depend on
        // telling three warm hues apart.
        Wrap(
          spacing: 18,
          runSpacing: 8,
          children: [
            _legend(theme, null, l.illnessWell),
            for (final s in Severity.values)
              _legend(theme, s, s.localizedLabel(l).toLowerCase()),
          ],
        ),
      ],
    );
  }

  Widget _legend(ThemeData theme, Severity? severity, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(
          color: _colorFor(severity, theme),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: theme.textTheme.labelSmall),
    ],
  );
}

class _IllnessRow extends StatelessWidget {
  const _IllnessRow({required this.log});

  final DevelopmentLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final severity = log.severity;
    final color = switch (severity) {
      Severity.severe => StatusColors.alert,
      Severity.moderate => StatusColors.warning,
      _ => StatusColors.neutral,
    };
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizedLogTitle(l, log),
                style: theme.textTheme.titleSmall,
              ),
              if (log.description.isNotEmpty)
                Text(
                  log.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(shortDate.format(log.date), style: theme.textTheme.labelSmall),
        if (severity != null) ...[
          const SizedBox(width: 12),
          Chip(
            label: Text(severity.localizedLabel(l)),
            visualDensity: VisualDensity.compact,
            side: BorderSide.none,
            backgroundColor: color.withValues(alpha: 0.14),
          ),
        ],
      ],
    );
  }
}
