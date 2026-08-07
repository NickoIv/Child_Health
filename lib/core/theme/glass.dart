import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Chrome you can see the page through.
///
/// His idea, and the one place in this app where it earns its keep: the tab bar
/// is the only surface that sits *over* content rather than beside it, and a
/// solid white plank across the bottom of every screen cuts the page off at a
/// line that means nothing. Frosted, the page runs under it and the bar reads
/// as something laid on top — which is what it is.
///
/// The cards keep their solid white. Glass under a paragraph is a readability
/// problem, and this app is read at three in the morning by somebody who has
/// not slept; the blur belongs on the furniture, not on the text.
class GlassPanel extends StatelessWidget {
  const GlassPanel({required this.child, super.key});

  final Widget child;

  /// Wide enough that the page beneath becomes colour rather than shapes.
  /// Below about 18 the text scrolling under the bar stays legible as text,
  /// which reads as a bug rather than as a material.
  static const blur = 24.0;

  /// How much of the surface is still surface.
  ///
  /// Not lower: the labels on the bar have to hold 4.5:1 against whatever
  /// happens to scroll under them, and at 0.6 a dark photograph passing
  /// underneath takes the unselected labels below it.
  static const opacity = 0.78;

  /// The tint the blur is seen through, per mode.
  static Color tint(Brightness b) => (b == Brightness.dark
          ? const Color(0xFF1A1817)
          : Colors.white)
      .withValues(alpha: opacity);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tint(brightness),
            // A hairline rather than a shadow. A shadow above a translucent
            // panel puts a grey band on the page it is meant to reveal.
            border: Border(
              top: BorderSide(color: Warm.hairline(brightness)),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A floating button that clears the glass.
///
/// Seven screens hang a button off the bottom right, and each of them is a
/// [Scaffold] inside the shell's [Scaffold] — which knows nothing about the
/// tab bar two levels up. Before the page ran under that bar it did not
/// matter; now the button lands behind it and cannot be pressed at all.
///
/// The shell hands the bar's height down as bottom padding, so lifting by
/// exactly that is the whole fix. It has to be read from [screenContext] —
/// the screen's own build context — rather than from inside the returned
/// widget: [Scaffold] wraps its floating-action-button slot in a
/// `MediaQuery.removePadding`, so a widget that asks in there is told zero.
///
/// On a wide window there is no bar, the padding is whatever the system asks
/// for, and this costs nothing.
Widget liftedFab(BuildContext screenContext, Widget fab) => Padding(
  padding: EdgeInsets.only(
    bottom: MediaQuery.paddingOf(screenContext).bottom,
  ),
  child: fab,
);
