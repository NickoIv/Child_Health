import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/motion.dart';
import '../../l10n/app_localizations.dart';

/// One tap from the home screen to a field with the keyboard already up.
///
/// This used to hold a recogniser of its own and it did not work — «микрофон
/// не работает». The Web Speech API is the wrong tool for this app: it opens
/// the microphone a second or two after it is asked, refuses to start twice on
/// the same page, hides its results behind a plugin layer that discards them,
/// and on an iPhone opened from the home screen it is not there at all. Every
/// one of those was worked around and it still lost sentences.
///
/// So the microphone is the one on her keyboard — the recogniser Apple and
/// Google tuned for Russian and Kazakh, the one she already uses to answer
/// messages, and the one that is a single key away from any focused field.
/// The app's job is to put the cursor in that field and raise the keyboard,
/// which is what this does and all it does.
///
/// It is still two actions to record a feed by speaking: press, dictate. The
/// difference is that the dictation works.
class AskButton extends ConsumerWidget {
  const AskButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Shaped like the thing it leads to rather than like the row it sat in.
    //
    // «Для ввода текста не заметна» — and it was not, because it looked like
    // every other soft row on the screen: same tint as the panel behind it,
    // same height, a label among labels. What it actually is is the way into
    // a field, so it is drawn as a field — a light box, an outline, a
    // placeholder-grey line of text and something to press at the end of it.
    // A shape a thumb recognises before the words are read.
    //
    // Louder colour was the other option and would have been wrong: the four
    // cards above are the primary way in, and nothing here should out-shout
    // them. This is legible instead of loud.
    final radius = BorderRadius.circular(18);
    final accent = Warm.accentOn(theme.brightness);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: PressScale(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Warm.card(theme.brightness),
            borderRadius: radius,
            border: Border.all(color: accent.withValues(alpha: 0.38), width: 1.4),
            boxShadow: Warm.shadow(theme.brightness),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () {
                // Asked for here, inside the tap, as well as on arrival: a
                // browser only raises the on-screen keyboard from inside a
                // real gesture, and the chat's own request happens a
                // navigation later, by which time the gesture is over.
                SystemChannels.textInput.invokeMethod<void>('TextInput.show');
                context.go(chatPath);
              },
              borderRadius: radius,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.homeSpeak,
                        // Placeholder weight and placeholder colour: it reads
                        // as an empty field waiting for her, which is what it
                        // is, rather than as a button announcing itself.
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Warm.onCardSoft(theme.brightness),
                        ),
                        // One line, always. A placeholder that wraps stops
                        // reading as a placeholder and starts reading as a
                        // paragraph — and Kazakh is a third longer than the
                        // Russian this was measured against.
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // The end of a field is where the thing that acts on it
                    // lives, and a keyboard is what this opens — including
                    // the microphone key on it, which is the recogniser that
                    // actually works. See the note at the top of this file.
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.keyboard_outlined,
                        size: 20,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
