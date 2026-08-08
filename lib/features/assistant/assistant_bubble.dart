import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/motion.dart';
import '../../l10n/app_localizations.dart';

/// The assistant, on every screen.
///
/// «Мало ли какой вопрос возникнет» — and until now the answer to that was
/// three taps: the assistant tab, then the card, then the field. A question
/// that occurs to somebody holding a baby does not survive three taps.
///
/// Bottom left, deliberately. Six screens already hang an add button off the
/// bottom right, and the home screen's microphone spans the width above the
/// tab bar; the left corner is the one place free on every screen in the app.
class AssistantBubble extends StatefulWidget {
  const AssistantBubble({required this.trigger, super.key});

  /// Whatever changing means "a new screen is on". The ripple runs again when
  /// it changes — which is the moment a question tends to occur.
  final String trigger;

  static const size = 56.0;

  /// Two rings per run, and then it stops.
  ///
  /// Not a repeating animation, and the reason is not only taste: a ticker
  /// that never finishes sits on top of every screen in the app, and
  /// `pumpAndSettle` waits for it forever — the first version of this took two
  /// hundred tests down with it. Something that breathes when a screen arrives
  /// and then rests is better on both counts, because movement in the corner
  /// of the eye is a cost even when nothing is timing it.
  static const period = Duration(milliseconds: 2400);

  /// How wide a ring grows before it is gone.
  static const haloScale = 1.6;

  @override
  State<AssistantBubble> createState() => _AssistantBubbleState();
}

class _AssistantBubbleState extends State<AssistantBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AssistantBubble.period,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void didUpdateWidget(AssistantBubble old) {
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
    final l = AppLocalizations.of(context);
    // A parent who has asked the system for less movement gets a plain circle.
    final still = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      button: true,
      label: l.assistantAskAi,
      child: Tooltip(
        message: l.assistantAskAi,
        child: Pressable(
          onTap: () => context.go('/assistant/chat'),
          borderRadius: AssistantBubble.size / 2,
          child: SizedBox(
            width: AssistantBubble.size,
            height: AssistantBubble.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!still)
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => Stack(
                      alignment: Alignment.center,
                      children: [
                        // Two rings, half a period apart, so the gesture reads
                        // as breathing rather than as a single blip.
                        for (final phase in const [0.0, 0.5])
                          _Halo(t: (_controller.value + phase) % 1.0),
                      ],
                    ),
                  ),
                const _Core(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One ring, leaving.
///
/// The scale and the fade run together, so it is thinnest exactly when it is
/// widest and there is never a hard edge anywhere on the page.
class _Halo extends StatelessWidget {
  const _Halo({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1 + (AssistantBubble.haloScale - 1) * t,
      child: Container(
        width: AssistantBubble.size,
        height: AssistantBubble.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Warm.accent.withValues(alpha: 0.22 * (1 - t)),
        ),
      ),
    );
  }
}

class _Core extends StatelessWidget {
  const _Core();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AssistantBubble.size,
      height: AssistantBubble.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: Warm.accentGradient,
        boxShadow: [
          BoxShadow(
            color: Warm.accent.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
    );
  }
}
