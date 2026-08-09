import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/care/active_timer.dart';
import '../../core/care/forecast_store.dart';
import '../../core/care/sleep_forecast.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/app_snack.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/development_log.dart';
import '../../providers.dart';
import '../shared/widgets.dart';

/// The next hour, estimated from the last fortnight.
///
/// It answers one question — «успею ли я в душ» — and answers it with a time
/// rather than an instruction. Where the number came from is printed on the
/// card, because a figure whose source is hidden is either magic or a
/// subscription, and this one is neither: it is her own entries, or the age
/// norms until there are enough of them.
class SleepForecastCard extends ConsumerWidget {
  const SleepForecastCard({super.key, this.now});

  /// Injectable so a window can be tested without waiting for the afternoon.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider);
    if (child == null) return const SizedBox.shrink();

    final moment = now ?? DateTime.now();
    final forecast = sleepForecastFor(
      ref.watch(logsProvider).value ?? const <DevelopmentLog>[],
      moment,
      ageMonths: child.ageInMonths,
      asleep: ref.watch(activeTimerProvider)?.kind == TimerKind.sleep,
    );
    if (forecast == null) return const SizedBox.shrink();

    final dismissedUntil = ref.watch(forecastStoreProvider);
    if (dismissedUntil != null && moment.isBefore(dismissedUntil)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final overdue = forecast.isOverdueAt(moment);
    final tone = SoftTone.lavender;
    final ink = tone.ink(theme.brightness);

    // The gap belongs to the card: when there is nothing to forecast it takes
    // no room at all, and a stray 16px of nothing reads as unfinished.
    return Padding(
      padding: const EdgeInsets.only(bottom: Warm.cardGap),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
        decoration: BoxDecoration(
          color: tone.fill(theme.brightness),
          borderRadius: BorderRadius.circular(Warm.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bedtime_outlined, size: 17, color: ink),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    (overdue ? l.sleepForecastOverdue : l.sleepForecastTitle)
                        .toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.microLabel(theme.brightness)
                        .copyWith(color: ink.withValues(alpha: 0.85)),
                  ),
                ),
                // A cross, not a menu: the way out has to be as cheap as the
                // way in, or the card is an advert.
                IconButton(
                  tooltip: l.suggestionDismiss,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => ref
                      .read(forecastStoreProvider.notifier)
                      .dismiss(now: moment),
                  icon: Icon(Icons.close, size: 18, color: ink),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                l.sleepForecastAt(timeOfDay.format(forecast.expectedAt)),
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.15,
                  color: ink,
                  fontFeatures: AppTheme.tabular,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.sleepForecastAwake(
                localizedDuration(l, forecast.awakeMinutesAt(moment)),
                localizedDuration(l, forecast.windowMinutes),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: ink.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            // Where the number came from, every time it is shown.
            Text(
              forecast.personal
                  ? l.sleepForecastFromHistory(forecast.samples)
                  : l.sleepForecastFromAge,
              style: theme.textTheme.bodySmall?.copyWith(
                color: ink.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 10),
            // The one thing to do about it, and it is the thing the app can
            // actually help with: start the clock when he does go down.
            FilledButton.tonalIcon(
              onPressed: () => _startSleepTimer(context, ref, child.id, l),
              icon: const Icon(Icons.timer_outlined, size: 18),
              label: Text(l.timerStart),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startSleepTimer(
    BuildContext context,
    WidgetRef ref,
    String childId,
    AppLocalizations l,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(activeTimerProvider.notifier)
        .start(kind: TimerKind.sleep, childId: childId);
    messenger.showSnackBar(appSnack(l.timerStarted, kind: SnackKind.done));
  }
}
