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

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: PressScale(
        child: Material(
          color: Warm.soft(theme.brightness),
          borderRadius: BorderRadius.circular(Warm.chipRadius),
          child: InkWell(
            onTap: () {
              // Asked for here, inside the tap, as well as on arrival: a
              // browser only raises the on-screen keyboard from inside a real
              // gesture, and the chat's own request happens a navigation
              // later, by which time the gesture is over.
              SystemChannels.textInput.invokeMethod<void>('TextInput.show');
              context.go(chatPath);
            },
            borderRadius: BorderRadius.circular(Warm.chipRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.keyboard_outlined,
                    size: 20,
                    color: Warm.accentOn(theme.brightness),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.homeSpeak,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Warm.onCard(theme.brightness),
                      ),
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
}
