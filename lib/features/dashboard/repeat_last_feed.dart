import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/labels.dart';
import '../../core/theme/app_snack.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/motion.dart';
import '../../l10n/app_localizations.dart';
import '../../models/child.dart';
import '../../models/development_log.dart';
import '../../providers.dart';
import '../shared/widgets.dart';

/// The same feed again, in one tap.
///
/// At four in the morning the entry is almost always the one before it: the
/// other side, about as long, nothing else to say. Three taps to record
/// something she has already recorded eleven times this week is three taps
/// too many.
///
/// It draws nothing until there is a feed to repeat, and nothing again once
/// the last one is old enough that repeating it would be a guess rather than
/// a shortcut — see [_staleAfter]. On a first morning with the app this row
/// does not exist.
class RepeatLastFeed extends ConsumerWidget {
  const RepeatLastFeed({required this.child, super.key});

  final Child child;

  /// Past this, the last feed is not what is happening now.
  ///
  /// Twelve hours. A feed from yesterday evening offered at noon would put
  /// the wrong side and the wrong length into the record with a single
  /// accidental tap, and a wrong entry costs more than a saved one gains.
  static const _staleAfter = Duration(hours: 12);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (ref.watch(isReadOnlyProvider)) return const SizedBox.shrink();

    final last = _lastFeed(
      ref.watch(logsProvider).value ?? const <DevelopmentLog>[],
      DateTime.now(),
    );
    if (last == null) return const SizedBox.shrink();

    // What it will write, spelled out — «как в прошлый раз» alone is asking
    // her to remember what the last one was, which is the thing she opened
    // the app to avoid.
    final what = [
      if (last.feedingSide case final side?) side.localizedLabel(l),
      if (last.durationMinutes case final minutes?)
        localizedDuration(l, minutes),
    ].join(', ');

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: PressScale(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _write(context, ref, last),
            borderRadius: BorderRadius.circular(Warm.chipRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.replay,
                    size: 18,
                    color: Warm.accentOn(theme.brightness),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      what.isEmpty ? l.homeRepeat : '${l.homeRepeat} — $what',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Warm.onCard(theme.brightness),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  DevelopmentLog? _lastFeed(List<DevelopmentLog> logs, DateTime now) {
    DevelopmentLog? best;
    for (final log in logs) {
      if (log.type != LogType.feeding || log.date.isAfter(now)) continue;
      // Solids are not the entry anybody repeats without thinking: the food
      // has a name, and last time's name is rarely this time's.
      if (log.feedingSide == FeedingSide.solid) continue;
      if (now.difference(log.date) > _staleAfter) continue;
      if (best == null || log.date.isAfter(best.date)) best = log;
    }
    return best;
  }

  Future<void> _write(
    BuildContext context,
    WidgetRef ref,
    DevelopmentLog last,
  ) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(logRepositoryProvider);

    final entry = DevelopmentLog(
      id: '',
      childId: child.id,
      date: DateTime.now(),
      type: LogType.feeding,
      title: LogType.feeding.label,
      feedingSide: last.feedingSide,
      durationMinutes: last.durationMinutes,
    );

    try {
      final saved = await repository.add(entry);
      // Undoable, like every other silent write in this app: a tap this
      // cheap is a tap that will sometimes be an accident.
      messenger.showAppSnack(
        appSnack(
          l.quickSaved(localizedLogTitle(l, entry)),
          kind: SnackKind.done,
          action: SnackBarAction(
            label: l.commonUndo,
            onPressed: () => repository.delete(saved.id),
          ),
        ),
      );
    } on Exception catch (e) {
      messenger.showAppSnack(
        appSnack(friendlyError(l, e), kind: SnackKind.problem),
      );
    }
  }
}
