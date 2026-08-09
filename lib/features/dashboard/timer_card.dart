import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/care/active_timer.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/app_snack.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/development_log.dart';
import '../../providers.dart';
import '../shared/widgets.dart';

/// The stretch that is happening right now, counting.
///
/// The whole point of the timer is that it is measured rather than estimated:
/// until now a feed was a number a parent guessed afterwards — «минут пятнадцать»
/// — and a nap was one of five preset lengths. Neither is a measurement, and
/// both were what a paper notebook still did better than this app.
///
/// It draws nothing when no clock is running, which is most of the day. When
/// one is, it is the first thing under the child's name, because a parent who
/// opens the app mid-feed opens it for exactly this.
class RunningTimerCard extends ConsumerStatefulWidget {
  const RunningTimerCard({required this.childId, super.key});

  final String childId;

  @override
  ConsumerState<RunningTimerCard> createState() => _RunningTimerCardState();
}

class _RunningTimerCardState extends ConsumerState<RunningTimerCard> {
  Timer? _tick;
  bool _saving = false;

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  /// One second, and only while there is something to count.
  ///
  /// Started and stopped from [build] rather than from initState: the timer
  /// can begin and end from the sheet, from another screen or from a reload
  /// finishing its read, and the card has no other notification that it did.
  void _sync({required bool running}) {
    if (running && _tick == null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!running && _tick != null) {
      _tick!.cancel();
      _tick = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timer = ref.watch(activeTimerProvider);
    // A viewer cannot start one, and a timer belonging to the other child is
    // not this screen's to stop.
    final mine = timer != null &&
        timer.childId == widget.childId &&
        !ref.watch(isReadOnlyProvider);

    _sync(running: mine);
    if (!mine) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    // The card is the colour of the button that started it, so the thing
    // running and the thing tapped are visibly the same thing.
    final tone = timer.kind == TimerKind.feeding ? SoftTone.peach : SoftTone.sand;
    final ink = tone.ink(theme.brightness);
    final forgotten = timer.looksForgotten(now);

    return Padding(
      padding: const EdgeInsets.only(bottom: Warm.cardGap),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: tone.fill(theme.brightness),
          borderRadius: BorderRadius.circular(Warm.cardRadius),
          boxShadow: Warm.shadow(theme.brightness),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  timer.kind == TimerKind.feeding
                      ? Icons.water_drop
                      : Icons.bedtime,
                  size: 16,
                  color: ink,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (timer.kind == TimerKind.feeding
                            ? l.timerFeeding
                            : l.timerSleep)
                        .toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.microLabel(theme.brightness).copyWith(
                      color: ink.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                Text(
                  [
                    if (timer.side != null) timer.side!.localizedLabel(l),
                    l.timerSince(timeOfDay.format(timer.startedAt)),
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ink.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w700,
                    fontFeatures: AppTheme.tabular,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // The one number on the screen anyone is meant to watch rather
            // than merely notice, so it is set at the size of the child's own
            // name and in figures that do not wobble as the seconds turn.
            Text(
              clockText(timer.elapsed(now)),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 40,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.4,
                height: 1.05,
                color: ink,
                fontFeatures: AppTheme.tabular,
              ),
            ),
            if (forgotten) ...[
              const SizedBox(height: 6),
              Text(
                l.timerForgotten,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ink.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : () => _stop(timer),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l.quickSaveButton),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: _saving ? null : _discard,
                  style: TextButton.styleFrom(foregroundColor: ink),
                  child: Text(l.timerDiscard),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Stop, and write down what was measured.
  ///
  /// The entry is dated at the *start* of the stretch, not at the tap: a feed
  /// that ran from 14:32 to 14:47 happened at 14:32, and dating it at the end
  /// would put every measured feed a quarter of an hour later than the ones
  /// entered by hand.
  Future<void> _stop(ActiveTimer timer) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final minutes = timer.minutesAt(DateTime.now());

    setState(() => _saving = true);
    try {
      await ref.read(logRepositoryProvider).add(
            DevelopmentLog(
              id: '',
              childId: timer.childId,
              date: timer.startedAt,
              type: timer.kind == TimerKind.feeding
                  ? LogType.feeding
                  : LogType.sleep,
              // The model's own wording, because it is what sits in Firestore.
              title: (timer.kind == TimerKind.feeding
                      ? LogType.feeding
                      : LogType.sleep)
                  .label,
              feedingSide: timer.side,
              durationMinutes: minutes,
            ),
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showAppSnack(
        appSnack(friendlyError(l, e), kind: SnackKind.problem),
      );
      return;
    }

    // Cleared only after the write: a failure has to leave the clock running,
    // or a measured feed is lost to a dropped connection.
    await ref.read(activeTimerProvider.notifier).clear();
    if (!mounted) return;
    setState(() => _saving = false);
    messenger.showAppSnack(
      appSnack(
        l.quickSaved(
          [
            timer.kind == TimerKind.feeding
                ? l.quickSheetFeeding.toLowerCase()
                : l.quickSheetSleepShort.toLowerCase(),
            if (timer.side != null) timer.side!.localizedLabel(l).toLowerCase(),
            localizedDuration(l, minutes),
          ].join(', '),
        ),
        kind: SnackKind.done,
      ),
    );
  }

  Future<void> _discard() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(activeTimerProvider.notifier).clear();
    if (!mounted) return;
    messenger.showAppSnack(appSnack(l.timerDiscarded));
  }
}

/// «12:04», and «1:02:30» once it has been running an hour.
///
/// Minutes and seconds rather than «12 мин»: a parent watching a feed wants to
/// see the thing move, and a figure that changes once a minute reads as a
/// screenshot.
String clockText(Duration elapsed) {
  final hours = elapsed.inHours;
  final minutes = elapsed.inMinutes % 60;
  final seconds = elapsed.inSeconds % 60;
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  return hours == 0 ? '$mm:$ss' : '$hours:$mm:$ss';
}
