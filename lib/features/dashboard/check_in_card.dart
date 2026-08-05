import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/care/check_in.dart';
import '../../core/care/check_in_store.dart';
import '../../l10n/app_localizations.dart';
import '../../models/development_log.dart';
import '../../models/json.dart';
import '../../providers.dart';

/// One question, on the morning after a short night.
///
/// The only card in the app addressed to the parent rather than about the
/// child. It asks how she is, takes one tap for an answer, and says one kind
/// thing back — and then it is done for the day.
///
/// What it deliberately does not do: name a condition, assess her, suggest she
/// is unwell, or send any of it anywhere. Three taps' worth of acknowledgement
/// is the entire feature, and anything more would be a claim it has no right
/// to make.
class CheckInCard extends ConsumerWidget {
  const CheckInCard({super.key, this.now});

  /// Injectable so the morning window can be tested without waiting for it.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(selectedChildProvider) == null) {
      return const SizedBox.shrink();
    }

    final moment = now ?? DateTime.now();
    final record = ref.watch(checkInStoreProvider);
    final answeredToday =
        record != null && dateOnly(record.day) == dateOnly(moment)
        ? record.answer
        : null;

    // Already answered: the reply stays for the day, the buttons do not.
    // Waved away: nothing at all until tomorrow.
    if (answeredToday == null) {
      final handledToday =
          record != null && dateOnly(record.day) == dateOnly(moment);
      if (handledToday) return const SizedBox.shrink();

      final logs = ref.watch(logsProvider).value ?? const <DevelopmentLog>[];
      if (!checkInDue(logs, moment, shownDay: record?.day)) {
        return const SizedBox.shrink();
      }
    }

    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return Padding(
      // The gap belongs to the card: on a morning with nothing to ask, it
      // takes no room at all.
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    answeredToday == null
                        ? l.checkInTitle
                        : _reply(l, answeredToday),
                    style: answeredToday == null
                        ? theme.textTheme.titleSmall
                        : theme.textTheme.bodySmall?.copyWith(height: 1.35),
                  ),
                ),
                if (answeredToday == null)
                  IconButton(
                    tooltip: l.suggestionDismiss,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => ref
                        .read(checkInStoreProvider.notifier)
                        .dismiss(now: moment),
                    icon: const Icon(Icons.close, size: 18),
                  ),
              ],
            ),
            if (answeredToday == null)
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 2),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 0,
                  children: [
                    for (final answer in CheckInAnswer.values)
                      TextButton(
                        onPressed: () => ref
                            .read(checkInStoreProvider.notifier)
                            .answer(answer, now: moment),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(_label(l, answer)),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _label(AppLocalizations l, CheckInAnswer answer) =>
      switch (answer) {
        CheckInAnswer.holdingUp => l.checkInHoldingUp,
        CheckInAnswer.tired => l.checkInTired,
        CheckInAnswer.veryHard => l.checkInVeryHard,
      };

  static String _reply(AppLocalizations l, CheckInAnswer answer) =>
      switch (answer) {
        CheckInAnswer.holdingUp => l.checkInReplyHoldingUp,
        CheckInAnswer.tired => l.checkInReplyTired,
        CheckInAnswer.veryHard => l.checkInReplyVeryHard,
      };
}
