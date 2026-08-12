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

  /// Three lengths, and nothing between them.
  ///
  /// [quick] is an acknowledgement — a surface dipping, a colour changing.
  /// [normal] is something arriving or leaving. [slow] is a number counting
  /// up, which is the only motion here anyone is meant to watch rather than
  /// merely notice.
  static const quick = Duration(milliseconds: 140);
  static const normal = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 650);
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

/// The same dip, for something that already handles its own taps.
///
/// [Pressable] builds the [InkWell] itself, which is right for a bare card and
/// wrong for anything that arrives with a gesture handler and an ink layer of
/// its own — a filled button, a [Material] with a painted fill. Scaling only
/// the inner [InkWell] there shrinks the label inside a pill that stays put.
///
/// This wraps the whole control instead and reads the pointer directly, so it
/// keeps its ripple and its disabled state and the surface still gives under
/// the finger. Same three percent, same hundred and ten milliseconds: one
/// animation applied twice, not a second one.
class PressScale extends StatefulWidget {
  const PressScale({required this.child, this.enabled = true, super.key});

  final Widget child;

  /// False on a control that cannot be pressed. A disabled button that dips
  /// says the tap landed, and it did not.
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
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
      child: Listener(
        // A Listener, not a GestureDetector: this watches the pointer and
        // never enters the arena, so the control underneath still wins the
        // tap, and a scroll that starts on it still scrolls.
        onPointerDown: (_) {
          if (widget.enabled) _set(true);
        },
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
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

// The pulsing halo that used to be here went with the microphone it was
// drawn around: dictation belongs to the assistant now, and the assistant's
// own button has [AssistantNavIcon]. The one remaining microphone — the
// button beside a note field in the quick sheets — carries its own.

/// The tick that says it was written down.
///
/// Eight hundred milliseconds, and it runs beside the confirmation rather than
/// in front of it: a full-screen success state would put a celebration between
/// a mother and the next thing she has to do. It never delays anything — the
/// sheet has already closed by the time this draws.
class SuccessCheck extends StatelessWidget {
  const SuccessCheck({
    this.size = 20,
    this.color,
    this.icon = Icons.check_circle_outline,
    super.key,
  });

  static const duration = Duration(milliseconds: 800);

  final double size;
  final Color? color;

  /// The glyph that draws itself in. Overridden where the tick already sits
  /// inside a disc of its own and a second ring would be one circle too many.
  final IconData icon;

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
        icon,
        size: size,
        color: color ?? Theme.of(context).colorScheme.inversePrimary,
      ),
    );
  }
}


/// A number that arrives at its value instead of being there already.
///
/// Only for figures a parent reads deliberately — the five in the digest, the
/// hours of sleep in the week. A count-up on a clock or a temperature would
/// be a lie told for effect: those are readings, and a reading that moves is
/// a reading you cannot trust.
///
/// Keyed on the value where it is used, so it counts when the day changes and
/// sits still through the rebuilds in between.
class CountUp extends StatelessWidget {
  const CountUp({
    required this.value,
    required this.builder,
    this.duration = Motion.slow,
    super.key,
  });

  final int value;
  final Duration duration;
  final Widget Function(BuildContext context, int value) builder;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: Motion.curve,
      builder: (context, shown, _) => builder(context, shown),
    );
  }
}

/// The shape of what is coming, while it is still on its way.
///
/// A spinner says "wait"; this says "here is a card, its contents are a
/// second behind". The difference matters on a screen opened forty times a
/// day, where the layout is already familiar and only the numbers are new.
///
/// The sweep is slow and low-contrast on purpose: it is a sign of life, not
/// a thing to look at, and it stops existing the moment the data lands.
class Skeleton extends StatefulWidget {
  const Skeleton({
    required this.width,
    required this.height,
    this.radius = 12,
    super.key,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.onSurface;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // A slow breath rather than a travelling highlight: a gradient
        // sweeping across six placeholders at once reads as a loading screen
        // from a different application.
        final t = (1 - (_controller.value * 2 - 1).abs());
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: base.withValues(alpha: 0.05 + t * 0.05),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

/// A tab icon that answers the finger.
///
/// The pill behind it was the only thing that moved, and a pill sliding under
/// an icon is the tab bar telling you where it went, not that it heard you.
/// This is the second half of that sentence: the glyph lifts two pixels and
/// swells a tenth on the way in, and settles rather than bounces.
///
/// Both the icon and the selected icon get one, so the movement runs whichever
/// of the two the bar happens to be cross-fading towards — and it runs once
/// per tap, because the value it animates to only changes when the tab does.
class NavIcon extends StatelessWidget {
  const NavIcon({required this.icon, required this.selected, super.key});

  final IconData icon;
  final bool selected;

  /// Small enough to be felt rather than watched. At 1.2 the icon collides
  /// with the pill's edge, which reads as a mistake at the size a tab bar is.
  static const grownScale = 1.12;
  static const lift = 2.0;
  static const duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: selected ? 1 : 0),
      duration: duration,
      // Overshoots by a hair and comes back. The one place in the app a
      // spring is right: this is a button being pressed, and a press that
      // arrives dead reads as a screenshot.
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, -lift * t),
        child: Transform.scale(scale: 1 + (grownScale - 1) * t, child: child),
      ),
      child: Icon(icon),
    );
  }
}

/// One screen replacing another.
///
/// A cross-fade with eight pixels of travel, in the direction of the tab that
/// was tapped — the same movement [Arrival] uses for a row, because a screen
/// and a row arriving differently is two ideas where one will do.
///
/// Nothing slides the full width. A phone that pushes whole screens sideways
/// on a tab bar is imitating navigation that did not happen: the tabs are
/// siblings, not a stack.
class TabSwitch extends StatefulWidget {
  const TabSwitch({required this.index, required this.child, super.key});

  final int index;
  final Widget child;

  @override
  State<TabSwitch> createState() => _TabSwitchState();
}

class _TabSwitchState extends State<TabSwitch> {
  /// Which way the last change went, so the new screen arrives from the side
  /// it came from.
  ///
  /// Once the tabs can be swiped between, a screen that fades in place
  /// contradicts the finger that just pushed it: the hand says the next tab
  /// is to the right and the animation says it appeared where it was. This
  /// reads the direction off the indices, so a tap on the bar gets the same
  /// treatment as a drag and neither has to be told which it was.
  int _previous = 0;

  @override
  void didUpdateWidget(TabSwitch old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _previous = old.index;
  }

  @override
  Widget build(BuildContext context) {
    final forward = widget.index >= _previous;
    // Small on purpose. The outgoing screen is gone the instant the new one is
    // asked for — see the layout builder — so a full-width slide would be a
    // screen sliding across bare background. This is the length of a nudge:
    // enough to say which direction, not enough to look like a page turn that
    // is not happening.
    final begin = Offset(forward ? 0.06 : -0.06, 0);

    return AnimatedSwitcher(
      duration: Motion.normal,
      switchInCurve: Motion.curve,
      switchOutCurve: Motion.curve,
      // The outgoing screen leaves the tree the moment the new one is asked
      // for, rather than fading out under it. Two screens alive at once is
      // two scrollables showing through each other — and, because the routes
      // underneath carry GlobalKeys, two widgets claiming the same key.
      layoutBuilder: (current, previous) =>
          current ?? const SizedBox.shrink(),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: begin, end: Offset.zero).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(widget.index), child: widget.child),
    );
  }
}
