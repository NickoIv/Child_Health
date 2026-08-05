import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/care/appreciation_store.dart';
import '../../core/care/heavy_day.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/development_log.dart';
import '../../models/family_member.dart';
import '../../providers.dart';

/// One sentence, on the evening of a hard day.
///
/// It says that a lot was done and stops there. It does not ask how she is,
/// suggest she rest, offer to help, or explain what any of the day's numbers
/// might mean — an app that starts consoling a tired mother is an app doing
/// something it is not qualified to do, however kindly it means it.
///
/// The thanks underneath is the only thing anybody else can put on this
/// screen, and it is a date on a document rather than a message: there is no
/// reply, because there is nothing to reply to.
///
/// Never for the viewer. The card is addressed to the person who had the day.
class AppreciationCard extends ConsumerWidget {
  const AppreciationCard({super.key, this.now});

  /// Injectable so a test can be given an evening without waiting for one.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(isReadOnlyProvider)) return const SizedBox.shrink();

    final day = now ?? DateTime.now();
    // Once a day, and once only: a sentence that reappears every time she
    // returns to the dashboard stops being kind by about the third time.
    if (ref.watch(appreciationStoreProvider.notifier).seenOn(day)) {
      return const SizedBox.shrink();
    }
    ref.watch(appreciationStoreProvider);

    final heavy = wasHeavyDay(
      ref.watch(logsProvider).value ?? const <DevelopmentLog>[],
      day,
    );
    // A thank-you shows whether or not the day was a hard one: it was sent
    // about this day, and holding it back until the arithmetic agrees would
    // be the app overruling the person who sent it.
    final thanked = (ref.watch(familyMembersProvider).value ?? const [])
        .any((m) => m.role == FamilyRole.viewer && m.thankedOnDay(day));
    if (!heavy && !thanked) return const SizedBox.shrink();

    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ink = SoftTone.rose.ink(theme.brightness);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.gap),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
        decoration: BoxDecoration(
          color: SoftTone.rose.fill(theme.brightness),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.volunteer_activism_outlined,
                  size: 20, color: ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (heavy)
                    Text(
                      l.appreciationHeavyDay,
                      style: theme.textTheme.bodyMedium?.copyWith(color: ink),
                    ),
                  if (heavy && thanked) const SizedBox(height: 8),
                  if (thanked)
                    Text(
                      l.appreciationThanks,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: ink,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: l.commonClose,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 18),
              onPressed: () =>
                  ref.read(appreciationStoreProvider.notifier).markSeen(day),
            ),
          ],
        ),
      ),
    );
  }
}
