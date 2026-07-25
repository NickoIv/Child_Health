import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/development_log.dart';
import '../../models/json.dart';
import '../../providers.dart';
import '../shared/widgets.dart';

/// Illness tracking: statistics and the calendar heat map, per 2.4.
class IllnessScreen extends ConsumerWidget {
  const IllnessScreen({super.key});

  static const _monthsShown = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider);
    if (child == null) return const NoChildPlaceholder();

    final logs = ref.watch(logsProvider).value ?? const <DevelopmentLog>[];
    final illnessLogs = logs.where((l) => l.type == LogType.illness).toList();
    final sickDays = ref.watch(illnessDaysProvider);

    return PageBody(
      children: [
        SectionCard(
          title: 'Статистика заболеваемости',
          icon: Icons.thermostat_outlined,
          child: _Stats(
            sickDays: sickDays,
            episodes: _episodeCount(sickDays),
            logs: illnessLogs,
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Тепловая карта за $_monthsShown месяцев',
          icon: Icons.calendar_month_outlined,
          child: _HeatMap(sickDays: sickDays, months: _monthsShown),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Эпизоды болезни',
          icon: Icons.list_alt_outlined,
          child: illnessLogs.isEmpty
              ? const EmptyState(
                  icon: Icons.sentiment_satisfied_outlined,
                  message: 'Записей о болезнях нет',
                  hint: 'Отметить день болезни можно в дневнике',
                )
              : Column(
                  children: [
                    for (var i = 0; i < illnessLogs.length; i++) ...[
                      if (i > 0) const Divider(height: 20),
                      _IllnessRow(log: illnessLogs[i]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  /// Consecutive sick days count as one episode; a gap of two or more clear
  /// days starts a new one.
  static int _episodeCount(Set<DateTime> days) {
    if (days.isEmpty) return 0;
    final sorted = days.toList()..sort();
    var episodes = 1;
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i].difference(sorted[i - 1]).inDays > 2) episodes++;
    }
    return episodes;
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
          caption: 'дней болезни всего',
          color: sickDays.isEmpty ? StatusColors.normal : null,
        ),
        StatTile(value: episodes.toString(), caption: 'эпизодов'),
        StatTile(value: lastYear.toString(), caption: 'дней за 12 месяцев'),
        StatTile(value: lastQuarter.toString(), caption: 'дней за 3 месяца'),
      ],
    );
  }
}

/// GitHub-style calendar: one square per day, coloured when the child was ill.
class _HeatMap extends StatelessWidget {
  const _HeatMap({required this.sickDays, required this.months});

  final Set<DateTime> sickDays;
  final int months;

  @override
  Widget build(BuildContext context) {
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
                        Container(
                          width: 13,
                          height: 13,
                          margin: const EdgeInsets.only(bottom: 3),
                          decoration: BoxDecoration(
                            color: day == null
                                ? Colors.transparent
                                : sickDays.contains(day)
                                ? StatusColors.alert
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _swatch(theme.colorScheme.surfaceContainerHighest),
            const SizedBox(width: 6),
            Text('здоров', style: theme.textTheme.labelSmall),
            const SizedBox(width: 20),
            _swatch(StatusColors.alert),
            const SizedBox(width: 6),
            Text('болел', style: theme.textTheme.labelSmall),
          ],
        ),
      ],
    );
  }

  Widget _swatch(Color color) => Container(
    width: 13,
    height: 13,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(3),
    ),
  );
}

class _IllnessRow extends StatelessWidget {
  const _IllnessRow({required this.log});

  final DevelopmentLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              Text(log.title, style: theme.textTheme.titleSmall),
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
            label: Text(severity.label),
            visualDensity: VisualDensity.compact,
            side: BorderSide.none,
            backgroundColor: color.withValues(alpha: 0.14),
          ),
        ],
      ],
    );
  }
}
