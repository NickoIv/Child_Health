import 'package:flutter/material.dart';

import 'motion.dart';

/// What a confirmation is about.
///
/// Three, and they are not severities: [done] means it is written down,
/// [problem] means it is not, [info] means neither. Nothing here is an alert —
/// an alert in this app is a red screen with a phone number on it, and a strip
/// that slides away after four seconds must never be mistaken for one.
enum SnackKind {
  done(Icons.check_rounded, Color(0xFF6FC79B)),
  info(Icons.bolt_rounded, Color(0xFFF2A25C)),
  problem(Icons.error_outline_rounded, Color(0xFFF08C7A));

  const SnackKind(this.icon, this.tint);

  final IconData icon;

  /// Read on the dark strip rather than on the page, so these are the light
  /// ends of the status colours rather than the status colours themselves.
  final Color tint;

  Duration get duration => switch (this) {
    // Long enough to read a sentence twice, because the reader is holding a
    // child and looked away halfway through the first time.
    SnackKind.problem => const Duration(seconds: 6),
    SnackKind.done => const Duration(seconds: 4),
    SnackKind.info => const Duration(seconds: 4),
  };
}

/// The one confirmation strip, so all twenty of them look like one app.
///
/// Every `showSnackBar` in the app goes through here. What it adds over the
/// Material default is the thing that was missing: a mark. The strip is the
/// only dark surface in the light theme, the icon lands on it a beat after it
/// arrives, and the tint says which of the three things happened before the
/// sentence has been read.
SnackBar appSnack(
  String message, {
  SnackKind kind = SnackKind.info,
  SnackBarAction? action,
  Duration? duration,
}) => SnackBar(
  content: _SnackBody(message: message, kind: kind),
  duration: duration ?? kind.duration,
  action: action,
  // Room for the icon disc without the text sitting against the edge.
  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
);

/// The icon and the sentence.
class _SnackBody extends StatelessWidget {
  const _SnackBody({required this.message, required this.kind});

  final String message;
  final SnackKind kind;

  static const discSize = 30.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Arrives after the strip does. The strip slides up from the bottom
        // edge, and a mark that is already there when it lands reads as part
        // of the furniture; one that appears half a beat later is the thing
        // the eye goes to.
        //
        // «Written down» keeps the tick the rest of the app draws for a save,
        // rather than a second animation that means the same thing.
        Container(
          width: discSize,
          height: discSize,
          decoration: BoxDecoration(
            color: kind.tint.withValues(alpha: 0.20),
            shape: BoxShape.circle,
          ),
          child: kind == SnackKind.done
              ? SuccessCheck(size: 18, color: kind.tint, icon: kind.icon)
              : TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Motion.normal,
                  curve: Curves.easeOutBack,
                  builder: (context, t, child) =>
                      Transform.scale(scale: t.clamp(0.0, 1.0), child: child),
                  child: Icon(kind.icon, size: 18, color: kind.tint),
                ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            message,
            style: Theme.of(context).snackBarTheme.contentTextStyle,
          ),
        ),
      ],
    );
  }
}

/// Shorthand for the common shape: a messenger, a sentence, a kind.
extension SnackMessenger on ScaffoldMessengerState {
  /// Replaces whatever is on screen rather than queueing behind it. Three
  /// feeds written in a row used to play three confirmations one after
  /// another, the last of them long after the phone went back in a pocket.
  void showApp(String message, {SnackKind kind = SnackKind.info}) {
    hideCurrentSnackBar();
    showSnackBar(appSnack(message, kind: kind));
  }
}
