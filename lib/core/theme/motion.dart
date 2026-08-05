import 'package:flutter/material.dart';

/// The only four animations in the app.
///
/// Deliberately four. Motion is how an interface tells you it heard you, and
/// past that it is decoration that costs a frame budget and a tired parent's
/// patience. There is no hero transition here, no parallax, no animated
/// background and no staggered choreography: a surface dips under the finger,
/// a new entry arrives instead of appearing, a save is confirmed with a tick,
/// and the microphone breathes while it is actually listening. Everything
/// else cuts.
///
/// The pulse is the only one that repeats, and it repeats only while a
/// recogniser is open — a card that animates continuously is a card that
/// keeps a phone's GPU awake for no one's benefit.

/// One curve for all of them.
///
/// Ease-out cubic: quick to start, slow to settle. Everything in this app that
/// moves is responding to a finger that has already landed, and a curve that
/// eases in as well would put a delay between the touch and the answer.
abstract final class Motion {
  static const curve = Curves.easeOutCubic;
}

/// A surface that gives a little under the finger.
///
/// Wraps its child's [InkWell] rather than replacing it — the ripple is still
/// the thing that says *where* the tap landed; the scale says *that* it did,
/// which on a card the size of a thumb the ripple alone does not.
class Pressable extends StatefulWidget {
  const Pressable({
    required this.child,
    required this.onTap,
    this.borderRadius = 18,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;

  /// Enough to feel, not enough to see. Three percent reads as give; ten
  /// reads as the button running away from the finger.
  static const pressedScale = 0.97;
  static const duration = Duration(milliseconds: 110);

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _down ? Pressable.pressedScale : 1.0,
      duration: Pressable.duration,
      curve: Motion.curve,
      child: InkWell(
        onTap: widget.onTap,
        onTapDown: widget.onTap == null ? null : (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: widget.child,
      ),
    );
  }
}

/// A new entry arrives rather than appearing.
///
/// Keyed by the record's own id where it is used, so this runs once when a
/// feed is written down and never again on the rebuilds that follow. A list
/// where every row re-animates on every state change is worse than one that
/// never animates at all.
class Arrival extends StatelessWidget {
  const Arrival({required this.child, super.key});

  static const duration = Duration(milliseconds: 260);

  /// Eight pixels up. Enough for the eye to catch the direction without the
  /// row appearing to fall into place.
  static const rise = 8.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Motion.curve,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * rise),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// The microphone, breathing, while it is listening and only then.
///
/// A halo that grows and fades rather than a spinner: a spinner says "wait",
/// and what this has to say is "go on, I can hear you". It stops the moment
/// [listening] goes false, which is also the moment the controller closes the
/// recogniser — there is no state in which this animates over a dead mic.
class MicPulse extends StatefulWidget {
  const MicPulse({
    required this.child,
    required this.listening,
    this.color,
    super.key,
  });

  static const duration = Duration(milliseconds: 900);

  final Widget child;
  final bool listening;
  final Color? color;

  @override
  State<MicPulse> createState() => _MicPulseState();
}

class _MicPulseState extends State<MicPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: MicPulse.duration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.listening) _controller.repeat();
  }

  @override
  void didUpdateWidget(MicPulse old) {
    super.didUpdateWidget(old);
    if (widget.listening == old.listening) return;
    if (widget.listening) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            if (widget.listening)
              // Painted behind, and never large enough to move anything: the
              // halo grows outside the button's own box rather than pushing
              // the layout around it.
              IgnorePointer(
                child: Transform.scale(
                  scale: 1 + t * 0.5,
                  child: Opacity(
                    opacity: (1 - t) * 0.35,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            child!,
          ],
        );
      },
    );
  }
}

/// The tick that says it was written down.
///
/// Eight hundred milliseconds, and it runs beside the confirmation rather than
/// in front of it: a full-screen success state would put a celebration between
/// a mother and the next thing she has to do. It never delays anything — the
/// sheet has already closed by the time this draws.
class SuccessCheck extends StatelessWidget {
  const SuccessCheck({this.size = 20, this.color, super.key});

  static const duration = Duration(milliseconds: 800);

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      // Settles rather than bounces. A springy tick on a medical record reads
      // as a game.
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: t, child: child),
      ),
      child: Icon(
        Icons.check_circle_outline,
        size: size,
        color: color ?? Theme.of(context).colorScheme.inversePrimary,
      ),
    );
  }
}
