import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/care/daily_reflection.dart';
import '../../core/care/reflection_store.dart';
import '../../core/l10n/labels.dart';
import '../../core/units/units.dart';
import '../../l10n/app_localizations.dart';
import '../../models/development_log.dart';
import '../../providers.dart';

/// The day added up, once, in the evening.
///
/// It reports and stops. The numbers are hers, the wording says nothing about
/// what they mean, and the second line thanks her for writing them down —
/// which is the only claim this card is entitled to make.
class ReflectionCard extends ConsumerWidget {
  const ReflectionCard({super.key, this.now});

  /// Injectable so the evening and the day boundary can be tested without
  /// waiting for either.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(selectedChildProvider) == null) {
      return const SizedBox.shrink();
    }

    final moment = now ?? DateTime.now();
    final logs = ref.watch(logsProvider).value ?? const <DevelopmentLog>[];
    final day = reflectionFor(
      logs,
      moment,
      dismissedDay: ref.watch(reflectionStoreProvider),
    );
    if (day == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final accent = theme.colorScheme.primary;
    final sleep = localizedDuration(l, day.sleepMinutes);

    return Padding(
      // The gap belongs to the card: with nothing to reflect on it takes no
      // room at all, not even a blank line.
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.nights_stay_outlined, size: 18, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.reflectionTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: l.suggestionDismiss,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => ref
                      .read(reflectionStoreProvider.notifier)
                      .dismiss(now: moment),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 28, right: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      _Figure(value: '${day.feedings}', label: l.countFeedings),
                      if (day.sleepMinutes > 0)
                        _Figure(value: sleep, label: l.countSleep),
                      _Figure(
                        value: '${day.nappies}',
                        label: l.reflectionNappies,
                      ),
                      // A reading that was taken, with no verdict attached to
                      // the number.
                      if (day.hasTemperature)
                        _Figure(
                          value: Units.formatTemperature(day.temperatureC!),
                          label: l.quickSheetTemperature.toLowerCase(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l.reflectionSummary(day.feedings, sleep),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.favorite_outline,
                        size: 15,
                        color: accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.reflectionSupport,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A number and what it counts, side by side rather than stacked: four of
/// these in a column would make the card as tall as the dashboard.
class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      textBaseline: TextBaseline.alphabetic,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      children: [
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
