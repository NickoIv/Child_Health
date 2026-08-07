import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/growth/who_standards.dart';
import '../../core/l10n/labels.dart';
import '../../l10n/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/units/units.dart';
import '../../models/child.dart';
import '../../models/development_log.dart';
import '../../models/reminder.dart';
import '../../providers.dart';
import '../shared/widgets.dart';
import 'dashboard_config.dart';
import 'focus_home.dart';
import 'now_card.dart';
import 'smart_card.dart';
import '../family/digest_card.dart';
import '../family/invite_banner.dart';
import '../family/moments_card.dart';

/// The home screen, in focus mode.
///
/// Four things and nothing else: who this is, the four things a parent
/// records without thinking, the last three that happened, and at most one
/// card with something to say. Everything the old dashboard also carried —
/// the eight configurable blocks, patterns, reflection, the digest, the week,
/// the shared photographs, the exports — moved to the assistant tab, where it
/// is read rather than passed on the way to logging a feed.
///
/// Nothing was removed. The measure of this screen is how quickly a woman
/// holding a baby in one arm can write down that she fed him, and every card
/// between her and those four buttons was costing her seconds she was paying
/// for at three in the morning.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider);
    if (child == null) return const NoChildPlaceholder();

    return PageBody(
      // A dashboard is a column of cards, and past about 900px the cards stop
      // being a column and become a wall.
      maxWidth: 900,
      children: [
        // Above everything, and gone the moment it is answered.
        const InviteBanner(),
        WarmHeader(child: child),
        const SizedBox(height: 20),
        SectionLabel(text: AppLocalizations.of(context).homeQuickLog),
        PrimaryActions(child: child),
        NightSleepLink(childId: child.id),
        const SizedBox(height: 20),
        // At most one, picked by priority rather than stacked.
        const SmartCard(),
        const RecentPreview(),
        // For a viewer, the day in five numbers and today's photographs. Both
        // draw nothing for the mother, who was there.
        const SizedBox(height: AppTheme.gap),
        const DigestCard(),
        const MomentsCard(),
      ],
    );
  }
}

/// The eight configurable blocks, kept whole and shown in the assistant tab.
///
/// They are still the parent's to arrange from settings — see
/// [DashboardLayoutEditor]. What changed is where they are read.
class DashboardBlocks extends ConsumerWidget {
  const DashboardBlocks({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final child = ref.watch(selectedChildProvider);
    if (child == null) return const SizedBox.shrink();

    final layout = ref.watch(dashboardLayoutProvider);
    if (layout.isEmpty) {
      return Column(
        children: [
          EmptyState(
            icon: Icons.dashboard_customize_outlined,
            message: l.dashAllHidden,
            hint: l.dashAllHiddenHint,
          ),
          const SizedBox(height: AppTheme.gap),
          FilledButton.tonalIcon(
            onPressed: () => context.go(settingsPath),
            icon: const Icon(Icons.tune),
            label: Text(l.dashConfigure),
          ),
        ],
      );
    }

    return Column(
      children: [
        for (final kind in layout) ...[
          _widgetFor(kind, child),
          const SizedBox(height: AppTheme.gap),
        ],
      ],
    );
  }

  Widget _widgetFor(DashboardWidgetKind kind, Child child) =>
      switch (kind) {
        // The block itself only. The four cards that used to trail it are
        // either the home screen's single smart card now or sit in the
        // insights section above this one.
        DashboardWidgetKind.now => NowCard(child: child),
        DashboardWidgetKind.growth => _GrowthCard(child: child),
        DashboardWidgetKind.illness => const _IllnessCard(),
        DashboardWidgetKind.milestones => const _MilestonesCard(),
        DashboardWidgetKind.upcoming => const _UpcomingCard(),
      };
}

/// The home-screen layout editor, embedded in settings.
class DashboardLayoutEditor extends ConsumerWidget {
  const DashboardLayoutEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final layout = ref.watch(dashboardLayoutProvider);
    final notifier = ref.read(dashboardLayoutProvider.notifier);
    final hidden = DashboardWidgetKind.values
        .where((k) => !layout.contains(k))
        .toList();

    return Column(
      children: [
        SectionCard(
          title: l.dashLayoutTitle,
          icon: Icons.dashboard_customize_outlined,
          child: layout.isEmpty
              ? EmptyState(
                  icon: Icons.visibility_off_outlined,
                  message: l.dashNoneSelected,
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
                        title: Text(layout[i].label(l)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: l.commonHide,
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
            title: l.dashHiddenBlocks,
            icon: Icons.visibility_off_outlined,
            child: Column(
              children: [
                for (final k in hidden)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(k.icon),
                    title: Text(k.label(l)),
                    trailing: IconButton(
                      tooltip: l.commonShow,
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
            label: Text(l.dashReset),
          ),
        ),
      ],
    );
  }
}

class _GrowthCard extends ConsumerWidget {
  const _GrowthCard({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final measurements = ref.watch(measurementsProvider);
    if (measurements.isEmpty) {
      return SectionCard(
        title: l.widgetGrowth,
        icon: Icons.show_chart_outlined,
        child: EmptyState(
          icon: Icons.straighten,
          message: l.growthNoMeasurements,
          compact: true,
        ),
      );
    }
    final last = measurements.last;
    final month = child.ageInMonthsAt(last.date);
    final weight = last.metrics.weightKg;
    final height = last.metrics.heightCm;
    final units = ref.watch(unitSystemProvider);

    return SectionCard(
      title: l.widgetGrowth,
      icon: Icons.show_chart_outlined,
      action: TextButton(
        onPressed: () => context.go('/growth'),
        child: Text(l.commonMore),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        children: [
          if (weight != null)
            _MetricWithPercentile(
              label: l.growthWeight,
              value: Units.formatWeight(weight, units),
              z: zScore(GrowthMetric.weight, child.gender, month, weight),
            ),
          if (height != null)
            _MetricWithPercentile(
              label: l.growthHeight,
              value: Units.formatHeight(height, units),
              z: zScore(GrowthMetric.height, child.gender, month, height),
            ),
          StatTile(
            value: shortDate.format(last.date),
            caption: l.growthLastMeasurement,
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
      caption: AppLocalizations.of(
        context,
      ).growthPercentileWith(label, percentileFromZ(z!).round()),
      color: color,
    );
  }
}

class _IllnessCard extends ConsumerWidget {
  const _IllnessCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final sickDays = ref.watch(illnessDaysProvider);
    final now = DateTime.now();
    final lastQuarter =
        sickDays.where((d) => now.difference(d).inDays <= 90).length;

    return SectionCard(
      title: l.widgetIllness,
      icon: Icons.thermostat_outlined,
      action: TextButton(
        onPressed: () => context.go('/illness'),
        child: Text(l.commonMore),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        children: [
          StatTile(
            value: '${sickDays.length}',
            caption: l.illnessDaysTotal,
            color: sickDays.isEmpty ? StatusColors.normal : null,
          ),
          StatTile(value: '$lastQuarter', caption: l.illnessLast3Months),
        ],
      ),
    );
  }
}

/// Milestones already recorded, newest first.
///
/// Separate from "последние записи" on purpose: feeds and nappies scroll past
/// in hours, while a first smile is the thing a parent will want to find in a
/// year. Burying it in a stream of routine care loses it.
class _MilestonesCard extends ConsumerWidget {
  const _MilestonesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final logs = ref.watch(logsProvider).value ?? const <DevelopmentLog>[];
    final milestones =
        logs.where((l) => l.type == LogType.milestone).toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    return SectionCard(
      title: l.widgetMilestones,
      icon: Icons.star_outline,
      accentColor: VizPalette.slot(4, theme.brightness),
      action: TextButton(
        onPressed: () => context.go('/diary'),
        child: Text(l.navDiary),
      ),
      child: milestones.isEmpty
          ? EmptyState(
              icon: Icons.star_outline,
              message: l.milestonesEmpty,
              hint: l.milestonesEmptyHint,
              compact: true,
            )
          : Column(
              children: [
                for (final m in milestones.take(5))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: VizPalette.slot(4, theme.brightness),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(localizedLogTitle(l, m))),
                        Text(
                          shortDate.format(m.date),
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Everything scheduled, vaccinations included.
///
/// The separate vaccination block that used to sit above this one read the
/// same provider, filtered it to one type, and linked to the same screen —
/// so on a newborn, whose only scheduled events *are* vaccinations, the two
/// cards were the same card twice.
class _UpcomingCard extends ConsumerWidget {
  const _UpcomingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final reminders = ref.watch(remindersProvider).value ?? const <Reminder>[];
    final now = DateTime.now();
    // Vaccinations used to be filtered out here, on the theory that they had
    // their own card. For a newborn they are the only thing scheduled, so
    // "ближайшие события" was permanently empty — the exclusion made the
    // card useless exactly when it mattered most.
    final soon =
        reminders
            .where(
              (r) =>
                  !r.isCompleted &&
                  r.scheduledTime.isAfter(
                    now.subtract(const Duration(days: 1)),
                  ),
            )
            .toList()
          ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    final visible = soon.take(4).toList();

    return SectionCard(
      title: l.widgetUpcoming,
      icon: Icons.event_outlined,
      action: TextButton(
        onPressed: () => context.go('/reminders'),
        child: Text(l.commonAll),
      ),
      child: visible.isEmpty
          ? EmptyState(
              icon: Icons.event_available_outlined,
              message: l.remindersNothingPlanned,
              hint: l.upcomingEmptyHint,
              compact: true,
            )
          : Column(
              children: [
                for (final r in visible)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(
                          switch (r.type) {
                            ReminderType.medication =>
                              Icons.medication_outlined,
                            ReminderType.vaccination => Icons.vaccines_outlined,
                            ReminderType.appointment =>
                              Icons.event_available_outlined,
                          },
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            r.type == ReminderType.vaccination
                                ? localizedVaccinationName(l, r.title)
                                : r.title,
                          ),
                        ),
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
