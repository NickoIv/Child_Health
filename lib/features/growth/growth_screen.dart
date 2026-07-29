import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/growth/who_standards.dart';
import '../../core/theme/app_theme.dart';
import '../../core/units/units.dart';
import '../../models/app_user.dart';
import '../../models/child.dart';
import '../diary/diary_screen.dart';
import '../../models/development_log.dart';
import '../../providers.dart';
import '../shared/widgets.dart';

/// Anthropometry: growth curves overlaid on the WHO reference, per 2.3.
class GrowthScreen extends ConsumerStatefulWidget {
  const GrowthScreen({super.key});

  @override
  ConsumerState<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends ConsumerState<GrowthScreen> {
  GrowthMetric _metric = GrowthMetric.weight;

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(selectedChildProvider);
    if (child == null) return const NoChildPlaceholder();

    // Measurements are derived from the log stream, so a failed query would
    // otherwise show up here as "no measurements" rather than as an error.
    final logsAsync = ref.watch(logsProvider);
    if (logsAsync.hasError) {
      return PageBody(
        children: [
          SectionCard(
            title: 'Динамика показателей',
            icon: Icons.show_chart_outlined,
            child: ErrorState(
              error: logsAsync.error!,
              onRetry: () => ref.invalidate(logsProvider),
            ),
          ),
        ],
      );
    }

    final measurements = ref.watch(measurementsProvider);
    final points = _pointsFor(child, measurements, _metric);

    return Scaffold(
      // The chart is where a parent notices a measurement is missing, so the
      // way to add one belongs here rather than only in the diary.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDiaryEntryForm(
          context,
          ref,
          childId: child.id,
          initialType: LogType.measurement,
        ),
        icon: const Icon(Icons.add),
        label: const Text('Добавить измерение'),
      ),
      body: PageBody(
        children: [
        SectionCard(
          title: 'Динамика показателей',
          icon: Icons.show_chart_outlined,
          action: SegmentedButton<GrowthMetric>(
            segments: [
              for (final m in GrowthMetric.values)
                ButtonSegment(value: m, label: Text(m.label)),
            ],
            selected: {_metric},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _metric = s.first),
          ),
          child: points.isEmpty
              ? const EmptyState(
                  icon: Icons.straighten,
                  message: 'Пока нечего показать на графике',
                  hint: 'Добавьте рост и вес в дневнике — кривая появится '
                      'после первого измерения, а нормы ВОЗ уже ждут',
                )
              : SizedBox(
                  height: 320,
                  child: _GrowthChart(
                    child: child,
                    metric: _metric,
                    points: points,
                    units: ref.watch(unitSystemProvider),
                  ),
                ),
        ),
          const SizedBox(height: 16),
          _LatestAssessment(child: child, metric: _metric, points: points),
          const SizedBox(height: 16),
          _MeasurementHistory(child: child, measurements: measurements),
        ],
      ),
    );
  }
}

/// A measurement reduced to what the chart needs: age in months and value.
typedef _Point = ({int month, double value, DateTime date});

List<_Point> _pointsFor(
  Child child,
  List<DevelopmentLog> logs,
  GrowthMetric metric,
) {
  final result = <_Point>[];
  for (final log in logs) {
    final value = switch (metric) {
      GrowthMetric.weight => log.metrics.weightKg,
      GrowthMetric.height => log.metrics.heightCm,
    };
    if (value == null) continue;
    result.add((
      month: child.ageInMonthsAt(log.date),
      value: value,
      date: log.date,
    ));
  }
  result.sort((a, b) => a.month.compareTo(b.month));
  return result;
}

class _GrowthChart extends StatelessWidget {
  const _GrowthChart({
    required this.child,
    required this.metric,
    required this.points,
    required this.units,
  });

  final Child child;
  final GrowthMetric metric;
  final List<_Point> points;
  final UnitSystem units;

  /// Metric in, display units out. Applied only when building spots and
  /// labels — every computation upstream stays in the units the WHO tables
  /// are indexed by.
  double _display(double metricValue) => switch (metric) {
    GrowthMetric.weight => Units.weightToDisplay(metricValue, units),
    GrowthMetric.height => Units.heightToDisplay(metricValue, units),
  };

  String get _unitLabel => switch (metric) {
    GrowthMetric.weight => Units.weightUnit(units),
    GrowthMetric.height => Units.heightUnit(units),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The axis must always cover the child's own data. Capping it at the
    // reference range would push every measurement past 5 years off-screen,
    // leaving an empty chart. The WHO curves simply stop where the tables do.
    final lastMonth = points.last.month;
    final maxMonth = lastMonth + 3 < 6 ? 6 : lastMonth + 3;

    final median = <FlSpot>[];
    final lower = <FlSpot>[];
    final upper = <FlSpot>[];
    for (var m = 0; m <= maxMonth; m++) {
      final md = medianFor(metric, child.gender, m);
      final lo = valueAtZ(metric, child.gender, m, -2);
      final hi = valueAtZ(metric, child.gender, m, 2);
      if (md != null) median.add(FlSpot(m.toDouble(), _display(md)));
      if (lo != null) lower.add(FlSpot(m.toDouble(), _display(lo)));
      if (hi != null) upper.add(FlSpot(m.toDouble(), _display(hi)));
    }

    final childSpots = [
      for (final p in points) FlSpot(p.month.toDouble(), _display(p.value)),
    ];

    final allValues = [
      ...lower.map((s) => s.y),
      ...upper.map((s) => s.y),
      ...childSpots.map((s) => s.y),
    ];
    final minY = allValues.reduce((a, b) => a < b ? a : b);
    final maxY = allValues.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) * 0.08;

    return Column(
      children: [
        Expanded(
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: maxMonth.toDouble(),
              minY: minY - pad,
              maxY: maxY + pad,
              gridData: FlGridData(
                drawVerticalLine: true,
                // Recessive by design: the grid orients, it does not compete
                // with the data.
                getDrawingHorizontalLine: (_) => FlLine(
                  color: VizPalette.grid(theme.brightness),
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (_) => FlLine(
                  color: VizPalette.grid(theme.brightness),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  axisNameWidget: const Text('возраст, месяцев'),
                  axisNameSize: 22,
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: maxMonth <= 12 ? 2 : 6,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: Text(_unitLabel),
                  axisNameSize: 20,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) => Text(
                      value.toStringAsFixed(metric == GrowthMetric.weight
                          ? 1
                          : 0),
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((s) {
                    // Only the child's own series is worth a tooltip; the
                    // reference curves would just add noise.
                    if (s.barIndex != 3) return null;
                    return LineTooltipItem(
                      '${s.y.toStringAsFixed(1)} $_unitLabel\n'
                      '${s.x.toInt()} мес.',
                      theme.textTheme.labelMedium ?? const TextStyle(),
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                _referenceLine(lower, theme, dashed: true),
                _referenceLine(upper, theme, dashed: true),
                _referenceLine(median, theme),
                LineChartBarData(
                  spots: childSpots,
                  isCurved: true,
                  curveSmoothness: 0.2,
                  // The one data series on this chart takes categorical slot
                  // 1 — validated, and far from both the violet chrome and
                  // the alert red, so it can never be mistaken for either.
                  color: _seriesColor(theme),
                  barWidth: 2.5,
                  dotData: FlDotData(
                    getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                      // 8px across, with a surface ring so points stay
                      // readable where they cross a reference curve.
                      radius: 4,
                      color: _seriesColor(theme),
                      strokeWidth: 2,
                      strokeColor: theme.colorScheme.surface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            _LegendDot(color: _seriesColor(theme), label: child.name),
            // Only advertise the reference when it is actually on the chart.
            if (median.isNotEmpty)
              const _LegendDot(
                color: VizPalette.muted,
                label: 'медиана ВОЗ',
              ),
            if (lower.isNotEmpty)
              _LegendDot(
                color: VizPalette.axis(theme.brightness),
                label: 'коридор ±2 SD',
                dashed: true,
              ),
          ],
        ),
        if (lastMonth > referenceMaxMonth) ...[
          const SizedBox(height: 8),
          Text(
            'Нормы ВОЗ определены до 5 лет, поэтому справочные кривые '
            'обрываются на 60 месяцах.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  static Color _seriesColor(ThemeData theme) =>
      VizPalette.slot(0, theme.brightness);

  /// The WHO curves are chart chrome, not a second series: they are the same
  /// context in every chart and never change with the data. Drawing them in a
  /// categorical hue would imply they are another child to compare against.
  LineChartBarData _referenceLine(
    List<FlSpot> spots,
    ThemeData theme, {
    bool dashed = false,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: dashed
          ? VizPalette.axis(theme.brightness)
          : VizPalette.muted,
      barWidth: 1.5,
      dashArray: dashed ? const [6, 4] : null,
      dotData: const FlDotData(show: false),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

/// Verdict on the most recent measurement: z-score, percentile and a colour.
class _LatestAssessment extends ConsumerWidget {
  const _LatestAssessment({
    required this.child,
    required this.metric,
    required this.points,
  });

  final Child child;
  final GrowthMetric metric;
  final List<_Point> points;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (points.isEmpty) return const SizedBox.shrink();
    final units = ref.watch(unitSystemProvider);
    final last = points.last;
    final z = zScore(metric, child.gender, last.month, last.value);
    if (z == null) {
      return const SectionCard(
        title: 'Оценка по нормам ВОЗ',
        icon: Icons.analytics_outlined,
        child: EmptyState(
          icon: Icons.help_outline,
          message: 'Возраст вне диапазона справочных таблиц (0–60 месяцев)',
        ),
      );
    }
    final verdict = verdictFromZ(z);
    final percentile = percentileFromZ(z);
    final color = switch (verdict) {
      GrowthVerdict.normal => StatusColors.normal,
      GrowthVerdict.low || GrowthVerdict.high => StatusColors.warning,
      _ => StatusColors.alert,
    };

    return SectionCard(
      title: 'Оценка по нормам ВОЗ',
      icon: Icons.analytics_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 32,
            runSpacing: 16,
            children: [
              StatTile(
                value: switch (metric) {
                  GrowthMetric.weight => Units.formatWeight(
                    last.value,
                    units,
                  ),
                  GrowthMetric.height => Units.formatHeight(
                    last.value,
                    units,
                  ),
                },
                caption: '${metric.label}, ${dayMonth.format(last.date)}',
              ),
              StatTile(
                value: '${percentile.round()}-й',
                caption: 'перцентиль',
                color: color,
              ),
              StatTile(
                value: z.toStringAsFixed(2),
                caption: 'z-оценка',
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  verdict == GrowthVerdict.normal
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(verdict.label)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Расчёт по нормам ВОЗ для детей 0–5 лет. Перцентиль показывает '
            'положение среди сверстников, а не диагноз: отклонение может быть '
            'и особенностью конкретного ребёнка. Оценивает врач.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasurementHistory extends ConsumerWidget {
  const _MeasurementHistory({
    required this.child,
    required this.measurements,
  });

  final Child child;
  final List<DevelopmentLog> measurements;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (measurements.isEmpty) return const SizedBox.shrink();
    final units = ref.watch(unitSystemProvider);
    final rows = measurements.reversed.toList();
    return SectionCard(
      title: 'История измерений',
      icon: Icons.table_rows_outlined,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 28,
          columns: [
            const DataColumn(label: Text('Дата')),
            const DataColumn(label: Text('Возраст')),
            DataColumn(
              label: Text('Вес, ${Units.weightUnit(units)}'),
              numeric: true,
            ),
            DataColumn(
              label: Text('Рост, ${Units.heightUnit(units)}'),
              numeric: true,
            ),
          ],
          rows: [
            for (final m in rows)
              DataRow(
                cells: [
                  DataCell(Text(shortDate.format(m.date))),
                  DataCell(Text('${child.ageInMonthsAt(m.date)} мес.')),
                  DataCell(
                    Text(
                      m.metrics.weightKg == null
                          ? '—'
                          : Units.weightToDisplay(
                              m.metrics.weightKg!,
                              units,
                            ).toStringAsFixed(1),
                    ),
                  ),
                  DataCell(
                    Text(
                      m.metrics.heightCm == null
                          ? '—'
                          : Units.heightToDisplay(
                              m.metrics.heightCm!,
                              units,
                            ).toStringAsFixed(1),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
