import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/care/conversation_memory.dart';
import '../../l10n/app_localizations.dart';

/// Picking a thought back up.
///
/// A parent typing a question here is interrupted more often than not, and
/// coming back to a blank field means starting the sentence again. This offers
/// the last one back — her own words, verbatim — and a way to say no.
///
/// There is no conversation behind it. One question, kept on this phone, gone
/// after a day: enough to feel continuous, far short of a transcript.
class ContinueBlock extends ConsumerWidget {
  const ContinueBlock({
    required this.onResume,
    super.key,
    this.now,
  });

  /// Fills the input with the remembered question rather than sending it —
  /// she may want to change a word before asking.
  final ValueChanged<String> onResume;

  /// Injectable so the day-long window can be tested without waiting a day.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = ref.watch(conversationMemoryProvider);
    if (last == null || !last.isFreshAt(now ?? DateTime.now())) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return Padding(
      // The gap belongs to the block: with nothing remembered it takes no
      // room at all.
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
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
                  Icons.history,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.chatContinueTitle,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                l.chatContinueLast(last.text),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                // Two lines and no more: a long question is a reminder, not
                // something to be read again in full.
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Wrap(
                spacing: 4,
                children: [
                  TextButton(
                    onPressed: () => onResume(last.text),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(l.chatContinueResume),
                  ),
                  TextButton(
                    onPressed:
                        ref.read(conversationMemoryProvider.notifier).forget,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                    ),
                    child: Text(l.chatContinueNew),
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
