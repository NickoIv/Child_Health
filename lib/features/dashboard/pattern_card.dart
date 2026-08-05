import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/care/pattern_store.dart';
import '../../core/care/patterns.dart';
import '../../l10n/app_localizations.dart';
import '../../models/development_log.dart';
import '../../providers.dart';
import '../shared/widgets.dart';

/// One sentence about how the last few days have gone.
///
/// Deliberately the quietest card on the screen: no figures, no chart, no
/// action attached to it. It exists because a parent living one day at a time
/// rarely gets to see that there is a shape to them at all — and that is the
/// whole of what it says.
class PatternCard extends ConsumerWidget {
  const PatternCard({super.key, this.now});

  /// Injectable so the three-day window can be tested without waiting three
  /// days for it.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(selectedChildProvider) == null) {
      return const SizedBox.shrink();
    }

    final moment = now ?? DateTime.now();
    final logs = ref.watch(logsProvider).value ?? const <DevelopmentLog>[];
    final observation = patternFor(
      logs,
      moment,
      dismissedDay: ref.watch(patternStoreProvider),
    );
    if (observation == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return Padding(
      // The gap belongs to the card: with nothing observed it takes no room
      // at all, not even a blank line.
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Icon(
                Icons.insights_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _text(l, observation),
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                ),
              ),
            ),
            IconButton(
              tooltip: l.suggestionDismiss,
              visualDensity: VisualDensity.compact,
              onPressed: () =>
                  ref.read(patternStoreProvider.notifier).dismiss(now: moment),
              icon: const Icon(Icons.close, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  static String _text(AppLocalizations l, PatternObservation observation) =>
      switch (observation.kind) {
        PatternKind.sleepThenFeeding => l.patternSleepThenFeeding,
        PatternKind.stableSleep => l.patternStableSleep,
        PatternKind.nightStart => l.patternNightStart(
          // Formatted here so the clock follows the interface language, the
          // way every other time in the app does.
          timeOfDay.format(
            DateTime(
              2026,
              1,
              1,
              observation.nightStartMinutes! ~/ 60,
              observation.nightStartMinutes! % 60,
            ),
          ),
        ),
      };
}
