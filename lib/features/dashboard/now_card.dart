import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_mode.dart';
import '../../models/child.dart';
import '../../models/development_log.dart';
import '../../models/json.dart';
import '../../models/reminder.dart';
import '../../providers.dart';

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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(now),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        child.name,
                        style: theme.textTheme.headlineSmall,
                      ),
                      Text(
                        child.ageLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(sickToday: sickToday, temperature: lastTemperature),
              ],
            ),

            if (dueToday.isNotEmpty) ...[
              const SizedBox(height: 16),
              for (final r in dueToday.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        r.type == ReminderType.vaccination
                            ? Icons.vaccines_outlined
                            : Icons.event_available_outlined,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Сегодня: ${r.title}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
            ],

            const SizedBox(height: 20),
            _QuickActions(child: child),
          ],
        ),
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
    final color = fever || sickToday
        ? StatusColors.alert
        : StatusColors.normal;
    final label = temperature != null
        ? '${temperature!.toStringAsFixed(1)} °C'
        : sickToday
        ? 'Болеет'
        : 'Здоров';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (temperature != null)
            Text(
              'последняя',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
    return Row(
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
