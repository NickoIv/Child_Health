import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/daily_care.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_mode.dart';
import '../../models/child.dart';
import '../../models/development_log.dart';
import '../../models/json.dart';
import '../../models/reminder.dart';
import '../../providers.dart';
import '../shared/widgets.dart';

/// The at-a-glance card: what is going on with this child right now, and the
/// three things a parent most often needs to do about it.
///
/// Designed for one hand and a short attention span. Everything is a large
/// tap target, nothing needs reading to act on, and the quick actions sit
/// below the summary where a thumb reaches.
class NowCard extends ConsumerWidget {
  const NowCard({required this.child, super.key});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final logs = ref.watch(logsProvider).value ?? const <DevelopmentLog>[];
    final reminders = ref.watch(remindersProvider).value ?? const <Reminder>[];

    final today = dateOnly(now);
    final sickToday = logs.any(
      (l) => l.type == LogType.illness && dateOnly(l.date) == today,
    );
    final lastTemperature = _lastTemperature(logs);
    final dueToday = reminders
        .where(
          (r) => !r.isCompleted && dateOnly(r.scheduledTime) == today,
        )
        .toList();

    final onGradient = theme.colorScheme.onPrimary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // The one warm, saturated surface in the app. It greets rather than
          // reports, which is the whole reason a tired parent opens this at all.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            decoration: BoxDecoration(
              gradient: AppTheme.welcomeGradient(theme.colorScheme),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(now),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onGradient.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        child.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: onGradient,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        child.ageLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: onGradient.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(
                  sickToday: sickToday,
                  temperature: lastTemperature,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dueToday.isNotEmpty) ...[
                  for (final r in dueToday.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              r.type == ReminderType.vaccination
                                  ? Icons.vaccines_outlined
                                  : Icons.event_available_outlined,
                              size: 16,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Сегодня: ${r.title}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
                const _TodayCounts(),
                const SizedBox(height: 14),
                _QuickActions(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static double? _lastTemperature(List<DevelopmentLog> logs) {
    // Logs arrive newest first, so the first hit is the latest reading.
    for (final l in logs) {
      final t = l.metrics.temperatureC;
      if (t != null) return t;
    }
    return null;
  }

  static String _greeting(DateTime now) {
    if (isNightAt(now)) return 'Доброй ночи';
    if (now.hour < 12) return 'Доброе утро';
    if (now.hour < 18) return 'Добрый день';
    return 'Добрый вечер';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.sickToday, required this.temperature});

  final bool sickToday;
  final double? temperature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fever = (temperature ?? 0) >= 38.0;
    final concerning = fever || sickToday;
    final label = temperature != null
        ? '${temperature!.toStringAsFixed(1)} °C'
        : sickToday
        ? 'Болеет'
        : 'Здоров';

    // Sits on the gradient, so the chip is a white card and the status colour
    // is carried by the icon and the text inside it. A tinted chip on a
    // saturated background would lose the distinction entirely.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            concerning ? Icons.thermostat : Icons.favorite,
            size: 18,
            color: concerning ? StatusColors.alert : StatusColors.normal,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: concerning ? StatusColors.alert : StatusColors.normal,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            temperature != null ? 'последняя' : 'сегодня',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Today's tally.
///
/// The numbers are coloured against the thresholds the knowledge base states —
/// six wet nappies, eight feeds — but only once the day is over. Telling a
/// mother at 9am that she is behind on feeds would be both wrong and cruel.
class _TodayCounts extends ConsumerWidget {
  const _TodayCounts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final care = ref.watch(dailyCareProvider);
    final now = DateTime.now();
    // "Complete" only near the end of the day; before that a low count says
    // nothing.
    final dayComplete = now.hour >= 21;

    if (care.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'Сегодня записей ещё нет. Кнопки ниже отмечают время сами.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final feedStatus = CareTargets.feedingStatus(
      care.feedings,
      dayComplete: dayComplete,
    );
    final nappyStatus = CareTargets.wetNappyStatus(
      care.wetNappies,
      dayComplete: dayComplete,
    );

    return Row(
      children: [
        _Count(
          value: '${care.feedings}',
          label: 'кормлений',
          status: feedStatus,
          hint: care.lastFeedingAt == null
              ? null
              : 'последнее в ${timeOfDay.format(care.lastFeedingAt!)}',
        ),
        _Count(
          value: '${care.wetNappies}',
          label: 'мокрых',
          status: nappyStatus,
        ),
        _Count(value: '${care.dirtyNappies}', label: 'стул'),
        if (care.sleepMinutes > 0)
          _Count(
            value: formatDuration(care.sleepMinutes),
            label: 'сна',
          ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({
    required this.value,
    required this.label,
    this.status = CareStatus.unknown,
    this.hint,
  });

  final String value;
  final String label;
  final CareStatus status;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (status) {
      CareStatus.onTrack => StatusColors.normal,
      CareStatus.watch => StatusColors.warning,
      CareStatus.unknown => null,
    };

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(color: color),
              ),
              if (status != CareStatus.unknown) ...[
                const SizedBox(width: 4),
                Icon(
                  status == CareStatus.onTrack
                      ? Icons.check_circle
                      : Icons.info_outline,
                  size: 14,
                  color: color,
                ),
              ],
            ],
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (hint != null)
            Text(
              hint!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;

    // Two rows rather than one: five targets squeezed across a phone would
    // each be too small to hit reliably with a baby in the other arm.
    // Feeding and nappies lead because for a newborn they are the whole day.
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.water_drop_outlined,
                label: 'Покормила',
                color: VizPalette.slot(2, brightness),
                onTap: () => _logFeeding(context, ref),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: Icons.child_care_outlined,
                label: 'Подгузник',
                color: VizPalette.slot(3, brightness),
                onTap: () => _logNappy(context, ref),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.thermostat,
                label: 'Температура',
                onTap: () => _logTemperature(context, ref),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: Icons.forum_outlined,
                label: 'Спросить',
                onTap: () => context.go('/assistant/chat'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: Icons.emergency_outlined,
                label: 'Тревога',
                color: StatusColors.alert,
                onTap: () => context.go('/assistant/triage'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _logFeeding(BuildContext context, WidgetRef ref) async {
    final side = await _pickOption<FeedingSide>(
      context,
      title: 'Кормление',
      options: {
        for (final s in FeedingSide.values)
          s: switch (s) {
            FeedingSide.left => Icons.chevron_left,
            FeedingSide.right => Icons.chevron_right,
            FeedingSide.bottle => Icons.local_drink_outlined,
          },
      },
      label: (s) => s.label,
    );
    if (side == null || !context.mounted) return;

    await _add(
      ref,
      DevelopmentLog(
        id: '',
        childId: child.id,
        date: DateTime.now(),
        type: LogType.feeding,
        title: 'Кормление',
        feedingSide: side,
      ),
      context,
      'Записано: кормление, ${side.label.toLowerCase()}',
    );
  }

  Future<void> _logNappy(BuildContext context, WidgetRef ref) async {
    final kind = await _pickOption<NappyKind>(
      context,
      title: 'Подгузник',
      options: {
        for (final k in NappyKind.values)
          k: switch (k) {
            NappyKind.wet => Icons.water_drop_outlined,
            NappyKind.dirty => Icons.eco_outlined,
            NappyKind.both => Icons.done_all,
          },
      },
      label: (k) => k.label,
    );
    if (kind == null || !context.mounted) return;

    await _add(
      ref,
      DevelopmentLog(
        id: '',
        childId: child.id,
        date: DateTime.now(),
        type: LogType.nappy,
        title: 'Подгузник',
        nappyKind: kind,
      ),
      context,
      'Записано: ${kind.label.toLowerCase()}',
    );
  }

  Future<void> _add(
    WidgetRef ref,
    DevelopmentLog log,
    BuildContext context,
    String confirmation,
  ) async {
    await ref.read(logRepositoryProvider).add(log);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(confirmation),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// A sheet of large buttons rather than a dropdown: this is tapped a dozen
  /// times a day, often one-handed and half-awake.
  Future<T?> _pickOption<T>(
    BuildContext context, {
    required String title,
    required Map<T, IconData> options,
    required String Function(T) label,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'Отметится текущим временем',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                for (final entry in options.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: () =>
                            Navigator.of(sheetContext).pop(entry.key),
                        icon: Icon(entry.value),
                        label: Text(label(entry.key)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _logTemperature(BuildContext context, WidgetRef ref) async {
    final value = await showDialog<double>(
      context: context,
      builder: (_) => const _TemperatureDialog(),
    );
    if (value == null) return;

    await ref
        .read(logRepositoryProvider)
        .add(
          DevelopmentLog(
            id: '',
            childId: child.id,
            date: DateTime.now(),
            // A fever is an illness day; anything else is just a measurement.
            // This is what makes the heat map fill in without extra taps.
            type: value >= 38.0 ? LogType.illness : LogType.measurement,
            title: 'Температура ${value.toStringAsFixed(1)} °C',
            metrics: Metrics(temperatureC: value),
            severity: value >= 39.0
                ? Severity.severe
                : value >= 38.0
                ? Severity.moderate
                : null,
          ),
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Записано: ${value.toStringAsFixed(1)} °C'),
          action: value >= 38.0
              ? SnackBarAction(
                  label: 'Что делать',
                  onPressed: () => context.go('/assistant/article/fever'),
                )
              : null,
        ),
      );
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        // Tall enough to hit reliably with a thumb while holding a child.
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: tint),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(color: tint),
            ),
          ],
        ),
      ),
    );
  }
}

/// Temperature entry without a keyboard: the realistic range is small, so
/// stepping through it beats typing while holding a baby.
class _TemperatureDialog extends StatefulWidget {
  const _TemperatureDialog();

  @override
  State<_TemperatureDialog> createState() => _TemperatureDialogState();
}

class _TemperatureDialogState extends State<_TemperatureDialog> {
  double _value = 37.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fever = _value >= 38.0;
    final color = fever ? StatusColors.alert : StatusColors.normal;

    return AlertDialog(
      title: const Text('Температура'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_value.toStringAsFixed(1)} °C',
              style: theme.textTheme.displaySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  onPressed: () => _step(-0.1),
                  icon: const Icon(Icons.remove),
                ),
                const SizedBox(width: 24),
                IconButton.filledTonal(
                  onPressed: () => _step(0.1),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            Slider(
              value: _value,
              min: 35.0,
              max: 42.0,
              divisions: 70,
              onChanged: (v) => setState(() => _value = v),
            ),
            if (fever)
              Text(
                'Это лихорадка. День будет отмечен как день болезни.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: color),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_value),
          child: const Text('Записать'),
        ),
      ],
    );
  }

  void _step(double delta) {
    setState(() {
      // Rounded to one decimal: floating point drift would otherwise show
      // 37.400000000000006 after a few taps.
      _value = ((_value + delta) * 10).roundToDouble() / 10;
      _value = _value.clamp(35.0, 42.0);
    });
  }
}
