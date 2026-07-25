import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/growth/who_standards.dart';
import '../../core/theme/app_theme.dart';
import '../../core/vaccination/national_calendar.dart';
import '../../models/child.dart';
import '../../models/development_log.dart';
import '../../models/reminder.dart';
import '../../providers.dart';
import '../shared/widgets.dart';
import 'dashboard_config.dart';
import 'now_card.dart';

/// Configurable home screen, per requirement 2.7.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(selectedChildProvider);
    if (child == null) return const NoChildPlaceholder();

    final layout = ref.watch(dashboardLayoutProvider);

    return Scaffold(
      body: _editing
          ? _LayoutEditor(onDone: () => setState(() => _editing = false))
          : PageBody(
              children: [
                for (final kind in layout) ...[
                  _widgetFor(kind, child),
                  const SizedBox(height: 16),
                ],
                if (layout.isEmpty)
                  const EmptyState(
                    icon: Icons.dashboard_customize_outlined,
                    message: 'Все виджеты скрыты',
                    hint: 'Нажмите «Настроить», чтобы вернуть их',
                  ),
              ],
            ),
      floatingActionButton: _editing
          ? null
          : FloatingActionButton.extended(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.dashboard_customize_outlined),
              label: const Text('Настроить'),
            ),
    );
  }

  Widget _widgetFor(DashboardWidgetKind kind, Child child) =>
      switch (kind) {
        DashboardWidgetKind.now => NowCard(child: child),
        DashboardWidgetKind.summary => _SummaryCard(child: child),
        DashboardWidgetKind.growth => _GrowthCard(child: child),
        DashboardWidgetKind.vaccinations => const _VaccinationCard(),
        DashboardWidgetKind.illness => const _IllnessCard(),
        DashboardWidgetKind.recentEntries => const _RecentEntriesCard(),
        DashboardWidgetKind.upcoming => const _UpcomingCard(),
      };
}

class _LayoutEditor extends ConsumerWidget {
  const _LayoutEditor({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(dashboardLayoutProvider);
    final notifier = ref.read(dashboardLayoutProvider.notifier);
    final hidden = DashboardWidgetKind.values
        .where((k) => !layout.contains(k))
        .toList();

    return PageBody(
      children: [
        SectionCard(
          title: 'Виджеты на экране',
          icon: Icons.dashboard_customize_outlined,
          action: TextButton(onPressed: onDone, child: const Text('Готово')),
          child: layout.isEmpty
              ? const EmptyState(
                  icon: Icons.visibility_off_outlined,
                  message: 'Ни один виджет не выбран',
                )
              : ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorderItem: notifier.reorder,
                  children: [
                    for (var i = 0; i < layout.length; i++)
                      ListTile(
                        key: ValueKey(layout[i]),
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(layout[i].icon),
                        title: Text(layout[i].label),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Скрыть',
                              onPressed: () => notifier.toggle(layout[i]),
                              icon: const Icon(Icons.visibility_off_outlined),
                            ),
                            ReorderableDragStartListener(
                              index: i,
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.drag_handle),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        if (hidden.isNotEmpty)
          SectionCard(
            title: 'Скрытые виджеты',
            icon: Icons.visibility_off_outlined,
            child: Column(
              children: [
                for (final k in hidden)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(k.icon),
                    title: Text(k.label),
                    trailing: IconButton(
                      tooltip: 'Показать',
                      onPressed: () => notifier.toggle(k),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: notifier.reset,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Вернуть стандартный набор'),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(logsProvider).value ?? const <DevelopmentLog>[];
    final milestones =
        logs.where((l) => l.type == LogType.milestone).length;

    return SectionCard(
      title: child.name,
      icon: Icons.child_care_outlined,
      child: Wrap(
        spacing: 36,
        runSpacing: 16,
        children: [
          StatTile(value: child.ageLabel, caption: 'возраст'),
          StatTile(
            value: shortDate.format(child.birthDate),
            caption: 'дата рождения',
          ),
          StatTile(value: '$milestones', caption: 'вех развития'),
          StatTile(value: '${logs.length}', caption: 'записей всего'),
        ],
      ),
    );
  }
}

class _GrowthCard extends ConsumerWidget {
  const _GrowthCard({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measurements = ref.watch(measurementsProvider);
    if (measurements.isEmpty) {
      return const SectionCard(
        title: 'Рост и вес',
        icon: Icons.show_chart_outlined,
        child: EmptyState(
          icon: Icons.straighten,
          message: 'Измерений пока нет',
        ),
      );
    }
    final last = measurements.last;
    final month = child.ageInMonthsAt(last.date);
    final weight = last.metrics.weightKg;
    final height = last.metrics.heightCm;

    return SectionCard(
      title: 'Рост и вес',
      icon: Icons.show_chart_outlined,
      action: TextButton(
        onPressed: () => context.go('/growth'),
        child: const Text('Подробнее'),
      ),
      child: Wrap(
        spacing: 36,
        runSpacing: 16,
        children: [
          if (weight != null)
            _MetricWithPercentile(
              label: 'Вес',
              value: '$weight кг',
              z: zScore(GrowthMetric.weight, child.gender, month, weight),
            ),
          if (height != null)
            _MetricWithPercentile(
              label: 'Рост',
              value: '$height см',
              z: zScore(GrowthMetric.height, child.gender, month, height),
            ),
          StatTile(
            value: shortDate.format(last.date),
            caption: 'последнее измерение',
          ),
        ],
      ),
    );
  }
}

class _MetricWithPercentile extends StatelessWidget {
  const _MetricWithPercentile({
    required this.label,
    required this.value,
    required this.z,
  });

  final String label;
  final String value;
  final double? z;

  @override
  Widget build(BuildContext context) {
    if (z == null) return StatTile(value: value, caption: label);
    final verdict = verdictFromZ(z!);
    final color = verdict == GrowthVerdict.normal
        ? StatusColors.normal
        : StatusColors.warning;
    return StatTile(
      value: value,
      caption: '$label · ${percentileFromZ(z!).round()}-й перцентиль',
      color: color,
    );
  }
}

class _VaccinationCard extends ConsumerWidget {
  const _VaccinationCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(remindersProvider).value ?? const <Reminder>[];
    final upcoming = upcomingVaccinations(reminders, limit: 3);

    return SectionCard(
      title: 'Ближайшие прививки',
      icon: Icons.vaccines_outlined,
      action: TextButton(
        onPressed: () => context.go('/reminders'),
        child: const Text('Все'),
      ),
      child: upcoming.isEmpty
          ? const EmptyState(
              icon: Icons.done_all,
              message: 'Предстоящих прививок нет',
            )
          : Column(
              children: [
                for (final r in upcoming)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(child: Text(r.title)),
                        const SizedBox(width: 12),
                        Text(
                          shortDate.format(r.scheduledTime),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _IllnessCard extends ConsumerWidget {
  const _IllnessCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sickDays = ref.watch(illnessDaysProvider);
    final now = DateTime.now();
    final lastQuarter =
        sickDays.where((d) => now.difference(d).inDays <= 90).length;

    return SectionCard(
      title: 'Заболеваемость',
      icon: Icons.thermostat_outlined,
      action: TextButton(
        onPressed: () => context.go('/illness'),
        child: const Text('Подробнее'),
      ),
      child: Wrap(
        spacing: 36,
        runSpacing: 16,
        children: [
          StatTile(
            value: '${sickDays.length}',
            caption: 'дней болезни всего',
            color: sickDays.isEmpty ? StatusColors.normal : null,
          ),
          StatTile(value: '$lastQuarter', caption: 'за последние 3 месяца'),
        ],
      ),
    );
  }
}

class _RecentEntriesCard extends ConsumerWidget {
  const _RecentEntriesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(logsProvider).value ?? const <DevelopmentLog>[];
    final recent = logs.take(4).toList();

    return SectionCard(
      title: 'Последние записи',
      icon: Icons.auto_stories_outlined,
      action: TextButton(
        onPressed: () => context.go('/diary'),
        child: const Text('Дневник'),
      ),
      child: recent.isEmpty
          ? const EmptyState(
              icon: Icons.edit_note,
              message: 'Записей пока нет',
            )
          : Column(
              children: [
                for (final l in recent)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(child: Text(l.title)),
                        const SizedBox(width: 12),
                        Text(
                          dayMonth.format(l.date),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _UpcomingCard extends ConsumerWidget {
  const _UpcomingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(remindersProvider).value ?? const <Reminder>[];
    final now = DateTime.now();
    final soon =
        reminders
            .where(
              (r) =>
                  !r.isCompleted &&
                  r.type != ReminderType.vaccination &&
                  r.scheduledTime.isAfter(
                    now.subtract(const Duration(days: 1)),
                  ),
            )
            .take(4)
            .toList();

    return SectionCard(
      title: 'Ближайшие события',
      icon: Icons.event_outlined,
      child: soon.isEmpty
          ? const EmptyState(
              icon: Icons.event_available_outlined,
              message: 'Ничего не запланировано',
            )
          : Column(
              children: [
                for (final r in soon)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(
                          r.type == ReminderType.medication
                              ? Icons.medication_outlined
                              : Icons.event_available_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(r.title)),
                        Text(
                          shortDate.format(r.scheduledTime),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
