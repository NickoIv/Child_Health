import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/care/active_timer.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../dashboard/timer_card.dart';

/// The running clock, carried onto every other screen.
///
/// A timer that is only visible on «Обзор» is a timer a parent forgets: she
/// starts a feed, goes to the diary to check yesterday, and the app gives her
/// no sign that anything is still counting. The number itself is the reminder,
/// so it travels — one line above the tab bar, where a thumb already is.
///
/// Deliberately not a second set of controls. It shows and it navigates; the
/// stopping, the saving and the discarding stay in one place, on the card that
/// owns them. Two «Сохранить» buttons for one feed is two chances to write it
/// down twice.
class RunningTimerStrip extends ConsumerStatefulWidget {
  const RunningTimerStrip({required this.location, super.key});

  /// Where the shell currently is. On «Обзор» the strip draws nothing: the
  /// full card is already on the screen, and a summary of the thing directly
  /// above it is noise.
  final String location;

  @override
  ConsumerState<RunningTimerStrip> createState() => _RunningTimerStripState();
}

class _RunningTimerStripState extends ConsumerState<RunningTimerStrip> {
  Timer? _tick;

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  /// One second, and only while something is being counted.
  ///
  /// This sits in the shell, so it is mounted on every screen in the app. A
  /// clock left ticking when nothing is running would schedule a frame a
  /// second forever — the whole app would never go idle, which drains a phone
  /// and hangs any test that waits for animations to finish.
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
    final child = ref.watch(selectedChildProvider);
    // Same three conditions the card applies, plus the screen it lives on: a
    // viewer cannot start one, and a clock belonging to the other child is not
    // this screen's business.
    final showing = timer != null &&
        child != null &&
        timer.childId == child.id &&
        !ref.watch(isReadOnlyProvider) &&
        widget.location != '/';

    _sync(running: showing);
    if (!showing) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    // The colour of the button that started it, exactly as on the card, so
    // the strip and the card read as one object rather than two features.
    final tone =
        timer.kind == TimerKind.feeding ? SoftTone.peach : SoftTone.sand;
    final ink = tone.ink(theme.brightness);

    return Material(
      color: tone.fill(theme.brightness),
      child: InkWell(
        onTap: () => context.go('/'),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 14, 10),
            child: Row(
              children: [
                Icon(
                  timer.kind == TimerKind.feeding
                      ? Icons.water_drop
                      : Icons.bedtime,
                  size: 17,
                  color: ink,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    timer.kind == TimerKind.feeding
                        ? l.timerFeeding
                        : l.timerSleep,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Figures that do not wobble as the seconds turn, at a size
                // that can be read without stopping what you are doing.
                Text(
                  clockText(timer.elapsed(now)),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: ink,
                    fontFeatures: AppTheme.tabular,
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}