import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// The assistant's own place in the tab bar.
///
/// It floated over the page for half a day and he was right about it: «кнопка
/// перекрывает информацию на экране». A control that is on every screen has to
/// live in the furniture, not on top of the content — so it sits in the bar
/// with the tabs, last, which on a phone held in the right hand is the corner
/// the thumb rests in.
///
/// It is not a tab. Tapping it opens the conversation over whatever is on
/// screen and closing it comes back here, so nothing is ever navigated away
/// from to ask a question.
class AssistantNavIcon extends StatefulWidget {
  const AssistantNavIcon({required this.trigger, super.key});

  /// Whatever changing means "a new screen is on". The ripple runs again when
  /// it changes — which is the moment a question tends to occur.
  final String trigger;

  /// Bigger than the 24 the other tabs draw at: this one is an action, not a
  /// place, and the bar should say so before the label is read.
  static const size = 34.0;

  /// How far the halo travels beyond the disc before it is gone.
  static const haloScale = 1.9;

  /// Three rings and a full turn of the glint, then rest.
  ///
  /// Not a repeating animation. A ticker that never finishes sits on top of
  /// every screen in the app and `pumpAndSettle` waits on it forever — the
  /// floating version took two hundred tests down that way. Something that
  /// comes alive when a screen arrives and then settles is better on both
  /// counts.
  static const period = Duration(milliseconds: 2600);

  @override
  State<AssistantNavIcon> createState() => _AssistantNavIconState();
}

class _AssistantNavIconState extends State<AssistantNavIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AssistantNavIcon.period,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void didUpdateWidget(AssistantNavIcon old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A parent who has asked the system for less movement gets a plain disc.
    final still = MediaQuery.disableAnimationsOf(context);

    return SizedBox(
      width: AssistantNavIcon.size,
      height: AssistantNavIcon.size,
      child: still
          ? const _Disc(glint: 0)
          : AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                return Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Three rings, evenly spaced through the run, so it reads
                    // as breathing rather than as one blip.
                    for (final phase in const [0.0, 0.34, 0.67])
                      _Halo(t: (t + phase) % 1.0),
                    _Disc(glint: t),
                  ],
                );
              },
            ),
    );
  }
}

/// One ring, leaving. Thinnest exactly when it is widest, so there is never a
/// hard edge anywhere near the tab labels.
class _Halo extends StatelessWidget {
  const _Halo({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1 + (AssistantNavIcon.haloScale - 1) * t,
      child: Container(
        width: AssistantNavIcon.size,
        height: AssistantNavIcon.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Warm.accent.withValues(alpha: 0.20 * (1 - t)),
        ),
      ),
    );
  }
}

/// The button itself: an accent disc with a sheen crossing it once per run.
///
/// The sheen is what makes this read as a thing with something in it rather
/// than as a coloured circle — and it costs one gradient rather than a second
/// animated layer.
class _Disc extends StatelessWidget {
  const _Disc({required this.glint});

  /// 0 to 1 through the run. The highlight sweeps across as it advances.
  final double glint;

  @override
  Widget build(BuildContext context) {
    // Out on the left before the run and off to the right after it, so the
    // sheen crosses once and is gone rather than sitting on the disc.
    final x = -1.6 + 3.2 * glint;

    return Container(
      width: AssistantNavIcon.size,
      height: AssistantNavIcon.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: Warm.accentGradient,
        boxShadow: [
          BoxShadow(
            color: Warm.accent.withValues(alpha: 0.40),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (glint > 0)
            ClipOval(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(x - 0.6, -1),
                    end: Alignment(x + 0.6, 1),
                    colors: [
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: 0.38),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          Transform.rotate(
            // A quarter turn across the run, back where it started. Enough to
            // catch the eye in the corner of the screen, not enough to spin.
            angle: math.sin(glint * math.pi) * 0.35,
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}
