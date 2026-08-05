import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/care/suggestion_store.dart';
import '../../core/care/suggestions.dart';
import '../../l10n/app_localizations.dart';
import '../../models/development_log.dart';
import '../../providers.dart';
import 'quick_log_sheet.dart';

/// One line, two buttons, and a cross.
///
/// The whole card is a shortcut to a button that is already on the screen
/// eighteen pixels below it, offered at the moment it is most likely to be
/// wanted. That is the entire claim: no advice, no conclusion about the child,
/// nothing it knows that she does not.
///
/// It stays small on purpose. A suggestion that takes up as much room as the
/// thing it suggests has stopped being a suggestion.
class SuggestionCard extends ConsumerWidget {
  const SuggestionCard({super.key, this.now});

  /// Injectable so the windows and the quiet hours can be tested without
  /// waiting for the afternoon.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider);
    if (child == null) return const SizedBox.shrink();

    final moment = now ?? DateTime.now();
    final logs = ref.watch(logsProvider).value ?? const <DevelopmentLog>[];
    final kind = suggestionFor(
      logs,
      moment,
      dismissedUntil: ref.watch(suggestionStoreProvider),
    );
    if (kind == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final accent = theme.colorScheme.primary;

    void open(bool startNow) => showQuickLogSheet(
      context,
      action: kind == SuggestionKind.afterSleep
          ? QuickLogAction.feeding
          : QuickLogAction.nappy,
      childId: child.id,
      // The card already asked "now or then"; the sheet must not ask again.
      startNow: startNow,
    );

    // The gap belongs to the card rather than to the dashboard around it:
    // when there is nothing to suggest the card takes no room at all, and a
    // stray 16px of nothing under the top block is exactly the kind of slack
    // that made the screen feel unfinished.
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
        decoration: BoxDecoration(
          // The app's own violet, at a fraction of its strength: present
          // enough to read as a suggestion, quiet enough to ignore.
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Icon(
                    kind == SuggestionKind.afterSleep
                        ? Icons.bedtime_outlined
                        : Icons.child_care_outlined,
                    size: 18,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      kind == SuggestionKind.afterSleep
                          ? l.suggestionAfterSleep
                          : l.suggestionNappy,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
                // A cross, not a menu: the way out has to be as cheap as the
                // way in, or the card is an advert.
                IconButton(
                  tooltip: l.suggestionDismiss,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => ref
                      .read(suggestionStoreProvider.notifier)
                      .dismiss(kind, now: moment),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 28, right: 6),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  FilledButton.tonal(
                    onPressed: () => open(true),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(l.quickTimeNow),
                  ),
                  TextButton(
                    onPressed: () => open(false),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(l.quickTimeChoose),
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
